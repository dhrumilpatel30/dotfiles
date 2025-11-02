-- ~/.config/nvim/lua/custom/plugins/java-dev.lua

return {
  -- ===================================================================
  -- Essential Java Tooling: LSP, Debugger, and more
  -- ===================================================================
  {
    'mfussenegger/nvim-jdtls',
    ft = { 'java' },
    dependencies = {
      'mfussenegger/nvim-dap',
      'rcarriga/nvim-dap-ui',
    },
    config = function()
      -- This is the heart of your Java setup.
      -- nvim-jdtls is a wrapper around the Eclipse JDT Language Server.
      local jdtls = require 'jdtls'

      -- Find the root of the project
      local root_markers = { '.git', 'mvnw', 'gradlew' }
      local root_dir = jdtls.setup.find_root(root_markers)
      if root_dir == nil then
        return
      end

      -- Define where to store the jdtls workspace data
      local data_dir = vim.fn.stdpath 'data' .. '/jdtls-workspace/' .. vim.fn.fnamemodify(root_dir, ':p:h:t')

      -- The bundles are the plugins for the Eclipse JDT Language Server.
      -- We need the debugger bundle.
      local bundles = {
        vim.fn.glob(vim.fn.stdpath 'data' .. '/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar', 1),
      }
      vim.list_extend(bundles, vim.fn.glob(vim.fn.stdpath 'data' .. '/mason/packages/java-test/extension/server/*.jar', 1))

      -- Main jdtls configuration
      jdtls.start_or_attach {
        cmd = { 'java', '-jar', vim.fn.glob(vim.fn.stdpath 'data' .. '/mason/packages/jdtls/jdtls-launcher/lib/launcher.jar'), '-data', data_dir },
        root_dir = root_dir,
        -- IMPORTANT: Your build.gradle uses Java 24.
        -- Make sure the `java` command above points to a JDK 24 installation,
        -- or specify the path to it here.
        -- on_attach = function(client, bufnr) ... end is handled by kickstart's lspconfig setup
        init_options = {
          bundles = bundles,
        },
      }

      -- Keymaps for Java-specific actions
      -- These will be available when the LSP attaches to a Java buffer.
      vim.api.nvim_create_autocmd('LspAttach', {
        pattern = '*.java',
        callback = function(args)
          local bufnr = args.buf
          -- Group keymaps under <leader>j for "Java"
          local wk = require 'which-key'
          wk.register({
            ['<leader>'] = {
              j = {
                name = '[J]ava',
                o = { jdtls.organize_imports, 'Organize Imports' },
                v = { jdtls.extract_variable, 'Extract Variable' },
                c = { jdtls.extract_constant, 'Extract Constant' },
                m = { jdtls.extract_method, 'Extract Method' },
                t = { jdtls.test_class, 'Test Class' },
                n = { jdtls.test_nearest_method, 'Test Nearest Method' },
                d = {
                  function()
                    require('dap').continue()
                  end,
                  'Debug Main Class',
                },
              },
            },
          }, { buffer = bufnr })

          -- Configure the DAP adapter for Java
          require('jdtls').setup_dap { hotcodereplace = 'auto' }
        end,
      })
    end,
  },

  -- ===================================================================
  -- Test Runner Integration
  -- ===================================================================
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'mfussenegger/nvim-dap',
      'rcasia/neotest-java', -- The adapter for Java tests
    },
    opts = function(_, opts)
      -- Get neotest-java to work with neotest
      opts.adapters = opts.adapters or {}
      table.insert(opts.adapters, require 'neotest-java')
    end,
    config = function(_, opts)
      require('neotest').setup(opts)
      -- Keymaps for testing
      local wk = require 'which-key'
      wk.register {
        ['<leader>'] = {
          t = {
            name = '[T]est',
            r = {
              function()
                require('neotest').run.run()
              end,
              'Run Nearest Test',
            },
            f = {
              function()
                require('neotest').run.run(vim.fn.expand '%')
              end,
              'Run Tests in File',
            },
            s = {
              function()
                require('neotest').run.run(vim.fn.getcwd())
              end,
              'Run All Tests',
            },
            d = {
              function()
                require('neotest').run.debug()
              end,
              'Debug Nearest Test',
            },
            o = {
              function()
                require('neotest').output.open()
              end,
              'Show Test Output',
            },
            S = {
              function()
                require('neotest').summary.toggle()
              end,
              'Toggle Test Summary',
            },
          },
        },
      }
    end,
  },

  -- ===================================================================
  -- Task Runner for Gradle/Spring Boot
  -- ===================================================================
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    opts = {
      size = 20,
      open_mapping = [[<c-\>]],
      direction = 'horizontal',
      shell = vim.o.shell,
    },
    config = function(_, opts)
      require('toggleterm').setup(opts)

      -- Helper function to run commands in a toggleable terminal
      local function term_exec(cmd)
        local term = require('toggleterm.terminal').Terminal:new {
          cmd = cmd,
          direction = 'float',
          close_on_exit = false,
        }
        term:toggle()
      end

      -- Keymaps for Gradle tasks
      local wk = require 'which-key'
      wk.register {
        ['<leader>'] = {
          g = {
            name = '[G]radle',
            b = {
              function()
                term_exec './gradlew build'
              end,
              'Build',
            },
            r = {
              function()
                term_exec './gradlew bootRun'
              end,
              'Run Spring Boot',
            },
            d = {
              function()
                term_exec './gradlew bootRun --debug-jvm'
              end,
              'Run Spring Boot (Debug)',
            },
            t = {
              function()
                term_exec './gradlew test'
              end,
              'Run Tests',
            },
            c = {
              function()
                term_exec './gradlew clean'
              end,
              'Clean',
            },
          },
        },
      }
    end,
  },

  -- ===================================================================
  -- File "Tabs" - A nice bufferline
  -- ===================================================================
  {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VimEnter',
    opts = {
      options = {
        mode = 'buffers', -- show open buffers
        separator_style = 'slant',
        show_buffer_close_icons = true,
        show_close_icon = true,
        diagnostics = 'nvim_lsp',
        -- Use this if you want to see diagnostics in the bufferline
        diagnostics_indicator = function(count, level, diagnostics_dict, context)
          local s = ' '
          for e, n in pairs(diagnostics_dict) do
            local icon = (e == 'error' and ' ') or (e == 'warning' and ' ') or (e == 'info' and ' ') or '󰌶 '
            s = s .. n .. icon
          end
          return s
        end,
      },
    },
    config = function(_, opts)
      require('bufferline').setup(opts)
      -- Keymaps to navigate buffers
      vim.keymap.set('n', '<S-l>', '<cmd>BufferLineCycleNext<CR>', { desc = 'Next buffer' })
      vim.keymap.set('n', '<S-h>', '<cmd>BufferLineCyclePrev<CR>', { desc = 'Previous buffer' })
    end,
  },
}
