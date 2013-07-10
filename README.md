This is a simple test for Stage3d on NME (tested only on Flash and Linux 64 bit)

First of all, In order to test this Stage3d sample, you will need to apply the patch stage3d.patch to your flash.3.5.1 dev folder

Then you will need to install the yoga library  
```haxelib install yoga```

then make sure you setup yoga (need to be done only once):  
```haxelib run yoga setup:system```

from now on you will be able to use yoga with the following:  
```yoga <command>```  
instead of  
```haxelib run yoga <command>```

Then you need to add a repository to get the dependencies from it (this is only to be done once, except if you modified your .yoga/settings.xml)  
```yoga setup:addRepo http://yoga.wighawag.com/repo```


Finally you just cd into the cloned repo and type:  
```yoga config```

This will generate a project.nmml that you can then execute with the following usual flash.command:  
```flash.test project.nmml flash```
```flash.test project.nmml cpp```


Notes:  
- if you do not want to install the yoga library you can just recreate yourself an nmml file as the project is very simple  
- Also the step where you add a repo to yoga is actually not necessary because this simple test does not depend on anything apart from the patched flash.itself yet  
- To find out more about yoga : https://github.com/wighawag/Yoga  

