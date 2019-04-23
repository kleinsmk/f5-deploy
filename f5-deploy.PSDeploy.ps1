Deploy f5-deploy {

    By FileSystem {
        FromSource 'C:\Powershell\Dev\f5-deploy'
        To 'C:\Program Files\WindowsPowerShell\Modules\f5-deploy'
        Tagged Prod
    }
}