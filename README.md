Welcome to Whisper!

** TO INSTRUCTORS **
    The files that run this program are (and relevant code for grading purposes):
        * ./parser/parser.rb (formerly rdparse.rb, from TDP007)
        * ./classes/nodes.rb (our AST nodes)
        * ./classes/scope.rb (our scope handler)
        * ./whisper/whisper.rb (the class Whisper, which uses parser.rb and implements our AST nodes)

    * For the curious, our (abandoned) previous implementation is availabe at ./Deprecated/whisper.[ylhc]
    
    * Unit tests are available at ./tests/test.rb
    
    * Documentation available in ./Documentation/ (includes Systemdokumentation)
    
    

To get started, clone this repository, 
go to the folder whisper/
$ cd whisper
and you should find the executable whisper.rb*
then type:
$ ./whisper.rb

**Recommended**
If you would like to have whisper on your machine
to execute and run anywhere in your terminal, run the
install script:

$ sudo ./whisper_install

*Note* if you have install problems, edit the install script to your liking.
       the 'manpath' has been set up to run on Viktor (ubuntu) and Warren (Arch) machines
       but must be edited (at least as far as we know) if you are running macOS. Not tested on
       any BSD distros.

After restarting your machine, simply enter:

$ whisper

For Help, run:

$ man whisper

While running Whisper, to exit, enter: 'exit'


-Viktor and Warren







