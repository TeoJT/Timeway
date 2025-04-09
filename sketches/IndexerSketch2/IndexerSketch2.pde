import java.util.HashSet;
import java.util.Set;
import java.util.AbstractMap;
import java.util.Collections;


class Indexer {
  
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //class Leaf {
  //  public String name = "";
  //  public int score = 0;
  //  public int variableScore = 0;
  //  public Leaf(String name, int score) {
  //    this.name = name;
  //    this.score = score;
  //  }
  //}
  
  public int arraysSize = 0;
  public int singlesSize = 0;
  public int totalSize = 0;
  public int totalNodes = 0;
  public int matches = 0;
  public int misses = 0;
  
  class Node {
    public int score = 0;
    private Node[] nodes = null;
    
    
    // For memory-saving.
    private Node singlemode_next = null;
    private char singlemode_nextChar = 0;
    
    public Node() {
      totalSize += 32;
      singlesSize += 16;
      totalNodes++;
    }
    
    private boolean singleMode() {
      return nodes == null;
    }
    
    public void increaseScore() {
      score++;
    }
    
    public void increaseScore(int amount) {
      score += amount;
    }
    
    public int getScore() {
      return score;
    }
    
    public Node accessNode(char ch) {
      int index = int(ch)-97;
      if (ch >= '0' && ch <= '9') {
        index = int(ch)-48+26;
      }
      
      if (index >= 0 && index < 36) {
        return nodes[index];
      }
      return null;
    }
    
    public void setNode(char ch, Node n) {
      int index = int(ch)-97;
      if (ch >= '0' && ch <= '9') {
        index = int(ch)-48+26;
      }
      
      if (index >= 0 && index < 36) {
        nodes[index] = n;
      }
    }
    
    public Node insert(char ch) {
      if (singleMode()) {
        // Empty (no nodes whatsoever)
        if (singlemode_nextChar == 0) {
          //println(ch+" New 1");
          singlemode_nextChar = ch;
          singlemode_next = new Node();
          misses++;
          return singlemode_next;
        }
        // One node matching
        else if (singlemode_nextChar == ch) {
          //println(ch+" Match (memory saving)");
          matches++;
          singlemode_next.increaseScore();
          return singlemode_next;
        }
        // One node turning into hashmap
        else {
          //println(ch+" Multiple (ohno)");
          nodes = new Node[36];
          totalSize += (8*36);
          arraysSize += (8*36);
          misses++;
          
          setNode(singlemode_nextChar, singlemode_next);
          
          Node newnode = new Node();
          setNode(ch, newnode);
          return newnode;
        }
      }
      else if (accessNode(ch) == null) {
        //println(ch+" New 2");
        Node newnode = new Node();
        misses++;
        setNode(ch, newnode);
        return newnode;
      }
      else {
        //println(ch+" What");
        Node n = accessNode(ch);
        misses++;
        n.increaseScore();
        return n;
      }
    }
    
    public Node get(char ch) {
      if (singleMode()) {
        if (singlemode_nextChar == ch)
          return singlemode_next;
        else 
          return null;
      }
      else {
        return accessNode(ch);
      }
    }
    
    public Set<HashMap.Entry<Character,Node>> getEntrySet() {
      Set<HashMap.Entry<Character,Node>> set = new HashSet<HashMap.Entry<Character,Node>>();
      if (singleMode()) {
        set.add(new AbstractMap.SimpleEntry<Character,Node>(singlemode_nextChar, singlemode_next));
        return set;
      }
      else {
        for (int i = 0; i < 36; i++) {
          Node n = nodes[i];
          if (n == null) continue;
          
          if (i < 10) {
            set.add(new AbstractMap.SimpleEntry<Character,Node>(char(i-26+48), n));
          }
          else {
            set.add(new AbstractMap.SimpleEntry<Character,Node>(char(i+97), n));
          }
        }
        return set;
      }
    }
    
    public ArrayList<Node> getAll() {
      ArrayList<Node> nodess = new ArrayList<Node>();
      if (singleMode()) {
        nodess.add(singlemode_next);
      }
      else {
        int highestScore = 0;
        Node highestScoring = null;
        for (int i = 0; i < 36; i++) {
          Node n = nodes[i];
          if (n == null) continue;
          
          //if (n.getScore() > 100) {
          //  nodess.add(n);
          //}
          if (trimmedSearch) {
            if (n.getScore() > highestScore) {
              highestScore = n.getScore();
              highestScoring = n;
            }
          }
          else {
            nodess.add(n);
          }
        }
        if (nodess.isEmpty()) {
          nodess.add(highestScoring);
        }
      }
      return nodess;
    }
    
  }
  
  
  
  private Node rootNode = null;
  //private HashMap<String, Leaf> allLeaves = new HashMap<String, Leaf>();
  //private HashMap<String, Long> nameToID = new HashMap<String, Long>();
  private long currentID = 0L;
  private boolean trimmedSearch = false;
  
  public Indexer() {
    rootNode = new Node();
  }
  
  public void insertString(String st) {
    insertString(st, st);
  }
  
  public void insertString(String name, String st) {
    insertString(name, st, 0);
  }
  
  public void insertString(String name, String st, int score) {
    Node currNode = rootNode;
    
    st = cleanString(st);
    
    int l = st.length();
    //println();
    for (int i = 0; i < l; i++) {
      char c = st.charAt(i);
      
      currNode = currNode.insert(c);
    }
  }
  
  public void removeString(String name, String st) {
    
  }
  
  public void increaseScore(String name, int increaseValue) {
    //if (allLeaves.containsKey(name)) {
    //  allLeaves.get(name).score += increaseValue;
    //}
  }
  
  public String generateSave() {
    indexerSave = "";
    generateSave(rootNode);
    return indexerSave;
  }
  
  
  private String indexerSave = "";
  
  private int cycles = 0;
  
  public void generateSave(Node n) {
    cycles++;
    if (cycles > 100000) {
      return;
    }
    for (HashMap.Entry<Character, Node> e : n.getEntrySet()) {
      Node currNode = e.getValue();
      if (currNode != null) {
        //print(e.getKey()+"(");
        indexerSave += e.getKey()+"(";
        generateSave(currNode);
        indexerSave += ")";
        //print(")");
      }
      
    }
  }
  
  public void deepSearch(Node currNode, ArrayList<String> searchResults, String currString) {
    Set<HashMap.Entry<Character,Node>> set = currNode.getEntrySet();
    
    if (set.size() == 0) {
      searchResults.add(currString);
      return;
    }
    
    for (HashMap.Entry<Character,Node> entry : set) {
      String newString = currString+entry.getKey();
      deepSearch(entry.getValue(), searchResults, newString);
    }
  }
  
  public void search(String st, ArrayList<String> searchResults) {
    Node currNode = rootNode;
    int index = 0;
    String currString = "";
    
    while (true) {
      currNode = currNode.get(st.charAt(index));
      currString += st.charAt(index);
      
      if (currNode == null) {
        return;
      }
      
      if (index >= st.length()) {
        deepSearch(currNode, searchResults, currString);
        return;
      }
    }
  }
  
  public void search(String st) {
    st = cleanString(st);
    
    if (st.length() == 0 || st.equals(" ")) {
      println("0 search results.");
      return;
    }
    
    ArrayList<String> results = new ArrayList<String>();
    
    search(st, results);
  }
  
  //public void findString(String st) {
  //  Node currNode = rootNode;
    
  //  st = st.toLowerCase();
    
  //  int l = st.length();
  //  for (int i = 0; i < l; i++) {
  //    char c = st.charAt(i);
      
  //    currNode = currNode.get(c);
  //    if (currNode == null) {
  //      println("Couldn't find \""+st+"\".");
  //      return;
  //    }
  //  }
    
  //  HashMap<String, Leaf> results = currNode.searchForEntries(st);
  //  if (results.size() == 0) println("No results for \""+st+"\".");
  //  else {
  //    println("Found from search query \""+st+"\": ");
  //    for (String entry : results.keySet()) {
  //      println(entry);
  //    }
  //  }
  //}
}


String cleanString(String st) {
  st = st.toLowerCase().replaceAll("[!\"£%\\^&\\*\\(\\)<>?,.#'\\[\\]:;#~@{}\\-=_+\\$\\n]", "");
  while (st.contains("  ")) {
    st = st.replaceAll("  ", " ");;
  }
  return st;
}


// Beat 108mb!

Indexer indexer;
//SlowIndexer indexer;
String query = "";

void setup() {
  size(768, 512);
  background(200);
  
  indexer = new Indexer();
  //indexer = new SlowIndexer();
  int before = millis();
  String[] indexFile = loadStrings("uhoh.txt");
  for (String s : indexFile) {
    indexer.insertString(s, s, 5);
  }
  
  File fff = (new File(sketchPath()+"/Journal/"));
  File[] files = fff.listFiles();
  for (File f : files) {
    String[] strrs = loadStrings(f.getAbsolutePath());
    String str = "";
    for (String s : strrs) {
      str += s+"\n";
    }
    //indexer.insertString(f.getName(), str, 1);
  }
  
  //indexer.increaseScore("A sardine grows from the soil 2020.mp3",999);
  
  indexer.increaseScore("Oh look it's summer", 347);
  //indexer.removeString("valentine.wav","valentine.wav");
  
  
  println("load time: "+(millis()-before)+"ms");
  System.gc();
  println("arraysSize: "+(indexer.arraysSize/1024)+"kb");
  println("singlesSize: "+(indexer.singlesSize/1024)+"kb");
  println("totalSize: "+(indexer.totalSize/1024)+"kb");
  println("--");
  println("totalNodes: "+(indexer.totalNodes/1024)+"K");
  println("matches: "+(indexer.matches/1024)+"K");
  println("misses: "+(indexer.misses/1024)+"K");
  println();
  long used = (Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory());
  println("Used memory: "+(used/1048576L)+"mb");
  
  
  
  String save = indexer.generateSave();
  String[] savess = new String[1];
  savess[0] = save;
  saveStrings("savee.txt", savess);
  //println(save);
  //println(save.length());
  
  //indexer.search("");
  
}


void keyPressed() {
  if (key == BACKSPACE) {
    if (query.length() > 0) {
      query = query.substring(0, query.length()-1);
    }
  }
  else {
    query += key;
  }
  
  println("\n\n\n\n\n\n\n\n\n\n\n\n\n");
  
  int before = millis();
  indexer.search(query);
  println("query time: "+(millis()-before)+"ms");
}

void draw() {
  background(200);
  textSize(64);
  textAlign(LEFT, CENTER);
  fill(0);
  float wi = width-50f;
  float x = sin(frameCount*0.05f)*(wi/2)+(wi/2);
  rect(x, 10, 50, 50);
  text(query, 10, height/2);
  //println(frameCount);
}
