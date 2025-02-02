class SlowIndexer {
  
  class Leaf {
    String content = "";
    String name = "";
    int score = 0;
    
    public Leaf(String name, String content, int score) {
      this.name = name;
      this.content = content;
      this.score = score;
    }
  }
  
  HashMap<String, Leaf> entries = new HashMap<String, Leaf>();
  
  public void insertString(String st) {
    insertString(st, st);
  }
  
  public void insertString(String name, String st, int score) {
    entries.put(name, new Leaf(name, cleanString(st), score));
  }
  
  public void insertString(String name, String st) {
    entries.put(name, new Leaf(name, cleanString(st), 0));
  }
  
  public void removeString(String name, String st) {
    entries.remove(name);
  }
  
  public String generateSave() {
    return "";
  }
  
  public void increaseScore(String name, int increaseValue) {
    entries.get(name).score += increaseValue;
  }
  
  public void search(String st) {
    st = cleanString(st);
    
    if (st.length() == 0 || st.equals(" ")) {
      println("0 search results.");
      return;
    }
    
    ArrayList<Leaf> results = new ArrayList<Leaf>();
    
    String[] keywords = st.split(" ");
    
    int i = 0;
    for (Leaf leaf : entries.values()) {
      boolean contains = true;
      for (String s : keywords) {
        contains &= (leaf.content.contains(s));
      }
      if (contains) {
        results.add(leaf);
      }
      i++;
    }
    println(i);
    
    
    Collections.sort(results, (o1, o2) -> o2.score - o1.score);
    
    //println(results.size()+" results");
    if (results.size() == 0) {
      println("0 slow search results for \""+st+"\".");
    }
    else {
      println("Slow search results for \""+st+"\":");
      
      int count = 1;
      for (Leaf leaf : results) {
        println(count+". "+leaf.name+" [score: "+leaf.score+"]");
        count++;
        if (count > 16) break;
      }
    }
  }
}
