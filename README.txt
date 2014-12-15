# Make sure you cd to $PROJECT/smali folder

# recache the package reference map
smali-cache-map.pl

# list all packages
smali-all-packages.pl

# see all packages which use packages under the directory
smali-dir-cluster.pl com/sysk/firstpay/ | smali-using-this-cluster.pl

# rename grabled packages
smali-dir-cluster.pl com/sysk/firstpay | grep -v firstpay | xargs -I , smali-rename.pl , com/sysk/firstpay/extra

# change package prefix
smali-change-prefix.pl com/ms/ezqx me/priezt/warrior

# change class name
smali-class-rename.pl com/a/a/a/a z/q/TestClass
