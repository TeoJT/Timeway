public void runAPI(Plugin p) {
  // The getCallOpCode method takes no arguments and returns an int
  // The getArgs method takes no arguments and returns an Object[]
  // The setRet method takes an Object as argument and returns void
  int opcode = p.getOpCode();
  Object[] args = p.getArgs();
  if (opcode == -1 || args == null) {
    println("Ohno");
    // error handling code
    return;
  }
  
  switch (opcode) {
    case 1:
    bump = (float)args[0];
    break;
    case 2:
    p.ret(specialNumber());
    break;
    default:
    println("Unknown opcode "+opcode);
    break;
  }
}
