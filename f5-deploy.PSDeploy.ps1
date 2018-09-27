Deploy f5-deploy {

    By FileSystem {
        FromSource '.\f5-deploy'
        To 'C:\Program Files\WindowsPowerShell\Modules\f5-deploy'
        Tagged Prod
    }
}