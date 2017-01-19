使い方
===========


```
git clone https://github.com/moobay9/vagrant-concrete5-shell.git
cd vagrant-concrete5-shell
vagrant up
```

だけです。  
必要であれば setup.sh の Parameter 部分を変更してください。  

* DB デフォルト

  - CONCRETE5_DB_NAME=concrete5
  - CONCRETE5_DB_USER=c5_user
  - CONCRETE5_DB_PASS=c5_password
  - CONCRETE5_DB_HOST=localhost

* URL
  http://172.16.10.10/

### 旧バージョンの clone 方法

```
git clone -b 5.7 https://github.com/moobay9/vagrant-concrete5-shell.git
```
