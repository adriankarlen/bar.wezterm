local M = {}

M.username = os.getenv "USER" or os.getenv "LOGNAME" or os.getenv "USERNAME"
return M
