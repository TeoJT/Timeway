import java.util.HashSet;
import java.util.Set;
import java.util.AbstractMap;
import java.util.Collections;


class Indexer {
  
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  class Leaf {
    public String name = "";
    public int score = 0;
    public int variableScore = 0;
    public Leaf(String name, int score) {
      this.name = name;
      this.score = score;
    }
  }
  
  class Node {
    public int score = 0;
    private Node[] nodes = null;
    private HashMap<String, Leaf> entries = null;
    
    
    // For memory-saving.
    private Node singlemode_next = null;
    private char singlemode_nextChar = 0;
    
    public Node() {
    }
    
    private boolean singleMode() {
      return nodes == null;
    }
    
    public void addEntry(String entry, Leaf leaf) {
      if (entries == null) {
        entries = new HashMap<String, Leaf>();
      }
      //entries.add(new Leaf(entry, 0));
      entries.put(entry, leaf);
    }
    
    public void removeEntry(String entry) {
      if (entries == null) {
        return;
      }
      entries.remove(entry);
    }
    
    public void increaseEntryScore(String entry, int val) {
      if (entries != null) {
        if (entries.containsKey(entry)) {
          entries.get(entry).score += val;
        }
      }
    }
    
    public boolean hasEntries() {
      return entries != null;
    }
    
    public HashMap<String, Leaf> searchForEntries(String toFind) {
      if (entries == null) return new HashMap<String, Leaf>();
      return entries;
    }
    
    public String getEntriesAsString() {
      //if (entries == null) {
      //  return "";
      //}
      //else {
      //  String ret = "";
      //  for (String s : entries.keySet()) {
      //    if (!nameToID.containsKey(s)) continue;
      //    ret += nameToID.get(s)+" ";
      //  }
      //  return ret;
      //}
      return "";
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
          singlemode_nextChar = ch;
          singlemode_next = new Node();
          return singlemode_next;
        }
        // One node matching
        else if (singlemode_nextChar == ch) {
          singlemode_next.increaseScore();
          return singlemode_next;
        }
        // One node turning into hashmap
        else {
          nodes = new Node[36];
          
          setNode(singlemode_nextChar, singlemode_next);
          
          Node newnode = new Node();
          setNode(ch, newnode);
          return newnode;
        }
      }
      else if (accessNode(ch) == null) {
        Node newnode = new Node();
        setNode(ch, newnode);
        return newnode;
      }
      else {
        Node n = accessNode(ch);
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
    
    Leaf leafToInsert = new Leaf(name, score);
    
    int l = st.length();
    for (int i = 0; i < l; i++) {
      char c = st.charAt(i);
      
      if (c == ' ') {
        if (i < l) { 
          currNode.addEntry(name, leafToInsert);
          currNode = rootNode;
        }
        continue;
      }
      
      currNode = currNode.insert(c);
    }
    
    currNode.addEntry(name, leafToInsert);
    //allLeaves.put(name, leafToInsert);
    //nameToID.put(name, currentID++);
  }
  
  public void removeString(String name, String st) {
    Node currNode = rootNode;
    
    st = cleanString(st);
    
    int l = st.length();
    for (int i = 0; i < l; i++) {
      char c = st.charAt(i);
      
      if (c == ' ') {
        if (i < l) { 
          currNode.removeEntry(name);
          currNode = rootNode;
        }
        continue;
      }
      
      currNode = currNode.get(c);
      if (currNode == null) return;
    }
    
    currNode.removeEntry(name);
    //allLeaves.remove(name);
    //nameToID.remove(name);
  }
  
  public void increaseScore(String name, int increaseValue) {
    //if (allLeaves.containsKey(name)) {
    //  allLeaves.get(name).score += increaseValue;
    //}
  }
  
  public void search(String searchQuery, int index, Node currNode, HashMap<String, Leaf> searchResults, int depth) {
    // Search until all characters in string used up
    if (index < searchQuery.length()) {
      char ch = searchQuery.charAt(index);
      
      Node n = currNode.get(ch);
      
      if (n != null) {
        search(searchQuery, index+1, n, searchResults, depth+1);
      }
    }
    
    // Once all characters in string are used up, we may have an incomplete search 
    // (e.g. "infor" should complete to "information")
    // This is what this section does.
    else {
      // Once we reach a leaf node we can begin to add results
      if (currNode.hasEntries()) {
        for (HashMap.Entry<String, Leaf> entry : currNode.searchForEntries(searchQuery).entrySet()) {
          searchResults.put(entry.getKey(), entry.getValue());
        }
      }
      
      // Continue searching
      // (the whole "infor" to "information" completion thing)
      for (Node n : currNode.getAll()) {
        if (n != null) {
          search(searchQuery, index+1, n, searchResults, depth+1);
        }
      }
    }
  }
  
  public String generateSave() {
    indexerSave = "";
    generateSave(rootNode);
    return indexerSave;
  }
  
  
  private String indexerSave = "";
  
  public void generateSave(Node n) {
    for (HashMap.Entry<Character, Node> e : n.getEntrySet()) {
      Node currNode = e.getValue();
      if (currNode != null) {
        print(e.getKey()+"(");
        indexerSave += e.getKey()+"(";
        generateSave(currNode);
        indexerSave += ")";
        print(")");
      }
    }
  }
  
  public void search(String st, HashMap<String, Leaf> searchResults) {
    search(st, 0, rootNode, searchResults, 0);
  }
  
  public void search(String st) {
    st = cleanString(st);
    
    if (st.length() == 0 || st.equals(" ")) {
      println("0 search results.");
      return;
    }
    
    
    
    HashMap<String, Leaf> results = new HashMap<String, Leaf>();
    
    String[] keywords = st.split(" ");
    
    trimmedSearch = true;
    search(keywords[0], results);
    
    HashSet<String> removeSet = new HashSet<String>();
    
    trimmedSearch = false;
    for (int i = 1; i < keywords.length; i++) {
      HashMap<String, Leaf> tempresults = new HashMap<String, Leaf>();
      search(keywords[i], tempresults);
      
      for (String name : results.keySet()) {
        if (!tempresults.containsKey(name)) {
          removeSet.add(name);
        }
      }
    }
    
    for (String remove : removeSet) {
      results.remove(remove);
    }
    
    ArrayList<Leaf> sortedObjects = new ArrayList<>(results.values());
    // Sort the ArrayList based on the score attribute
    Collections.sort(sortedObjects, (o1, o2) -> o2.score - o1.score);
    
    //println(results.size()+" results");
    if (results.size() == 0) {
      println("0 search results for \""+st+"\".");
    }
    else {
      println("Search results for \""+st+"\":");
      int count = 1;
      for (Leaf leaf : sortedObjects) {
        println(count+". "+leaf.name+" [score: "+leaf.score+"]");
        count++;
        if (count > 16) break;
      }
    }
  }
  
  public void findString(String st) {
    Node currNode = rootNode;
    
    st = st.toLowerCase();
    
    int l = st.length();
    for (int i = 0; i < l; i++) {
      char c = st.charAt(i);
      
      currNode = currNode.get(c);
      if (currNode == null) {
        println("Couldn't find \""+st+"\".");
        return;
      }
    }
    
    HashMap<String, Leaf> results = currNode.searchForEntries(st);
    if (results.size() == 0) println("No results for \""+st+"\".");
    else {
      println("Found from search query \""+st+"\": ");
      for (String entry : results.keySet()) {
        println(entry);
      }
    }
  }
}


String cleanString(String st) {
  st = st.toLowerCase().replaceAll("[!\"£%\\^&\\*\\(\\)<>?,.\\/#'\\[\\]:;#~@{}\\-=_+\\$\\n]", " ");
  while (st.contains("  ")) {
    st = st.replaceAll("  ", " ");;
  }
  return st;
}

String firstJournalEntry = """
23:18 01/06/2019

So...

Look at that, I have decided to keep a journal. I dunno how much I'll write in there. Maybe update it on a regular basis. Plus, it's always nice to look back at stuff, even if my nostalgia feelings are pretty much corrupted. And it's also great to look at a past me and my thoughts. My first journal entry, on the first day of summer.

So... today, Adrian came over. He's getting pretty suspicious about the fact that I hide what's in my room. Nvm. It was actually fun playing with him today. Stick wars, the bridge, PVP, and of course, build battle. Working as a team, we won TWO FREAKIN TIMES! How? References. Where we had to build a watch, we made the clock from DHMIS, and BOY was it successful. Then we did an angry meme face. SUCCESS.

That took up the majority of the afternoon. I then proceded to clean my room, but I had found an unused television in the games room, with a HDMI port. Seeing this feature, I took the heavy thing into my room, plugged it into my computer, and the quality sucked. Oh well.

The person who is inventing Ponish, Fialia Byera (who might possibly be a girl, that would be awkward) spoke to me again today. It's amazing how I got that "friend" simply by just being there on Amino; I didn't interact with people at all to get that person.

So, what else? Pure dissatisfaction. My watch device will no longer work with the SD card and I may possible have to replace the entire thing. I'm beginnig to dislike my project as there's always the risk of things just not working for no reason at all.

There's more to this cake of dissatisfaction; lately I've been feeling like the MLP fandom is dying and I want to be happy with what I have. It sucks, cus once I have that feeling, it's so difficult to get rid of. On top of that, there was a comic dub on that one comic about the farting G5 Twilight. Ugh. There's so many people in the fandom who are just booing at the upcoming G5, it makes me sick. Sure, earth pony Twilight might be a thing many people don't want (me included), but the art design and style isn't even COMFIRMED yet! Can we just judge G5 when it actually releases, dammit?!

What else...oh yeah. Was downloading pony art but Mum forced me to bed, forcing me to end the pony art collecting early. Thanks Mum...

Oh yeah. I also got an ok haircut.

So in a nutshell, today started off fine, but then got dissatisfying at the end. Oh well. At least I wrote this entry. And I'm looking forwards to writing more entries in the future!

(stupid people for wanting G5 MLP to be cancelled when nobody knows what it's even going TO BE LIKE)
""";



SlowIndexer indexer;
String query = "";

void setup() {
  size(768, 512);
  background(200);
  
  indexer = new SlowIndexer();
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
    indexer.insertString(f.getName(), str, 1);
  }
  
  indexer.increaseScore("A sardine grows from the soil 2020 a.mp3",999);
  
  indexer.insertString("Oh look it's summer", firstJournalEntry);
  indexer.increaseScore("Oh look it's summer", 347);
  indexer.removeString("valentine.wav","valentine.wav");
  
  
  println("load time: "+(millis()-before)+"ms");
  
  
  
  String save = indexer.generateSave();
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
