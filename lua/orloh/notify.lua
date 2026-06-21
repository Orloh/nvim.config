local MiniNotify = require("mini.notify")

MiniNotify.setup({
    content = {
        format = function(notif)
            return notif.msg
        end
    },
})

vim.notify = MiniNotify.make_notify()
