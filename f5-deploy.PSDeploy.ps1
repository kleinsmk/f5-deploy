Deploy f5-deploy {

    By FileSystem {
        FromSource '.\'
        To 'C:\Users\551479\Desktop\testdeploy'
        Tagged Prod
    }
}