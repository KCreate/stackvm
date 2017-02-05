crystal build src/StackMachine.cr -o vm;
./vm asm $@ > tmp.bc;
shift;
./vm run tmp.bc $@;
echo $?;
rm tmp.bc;
