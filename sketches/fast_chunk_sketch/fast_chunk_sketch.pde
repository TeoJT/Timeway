
final int CHUNK_BYTES_SIZE = 8;
final int MAX_XY_LIMIT = 65536;
final int TERRAIN_CACHE_VERSION = 1;

HashMap<Integer, Integer> rowPointers = null;
HashMap<Integer, Integer> rowLengths = null;
byte[] chunkCacheBlock = null;

class XYCoords {
  public int x = 0;
  public int y = 0;
  public XYCoords(int x, int y) {
    this.x = x;
    this.y = y;
  }
}

// converts 0 1 2 3 4 5 to 0 1 -1 2 -2
private int denumerate(int x) {
  if (x == 0) {
    return 0;
  }
  // even
  else if (x%2 == 0) {
    return -x/2;
  }
  // odd
  else {
    return (x/2)+1;
  }
}

// converts 0 1 -1 2 -2 to 0 1 2 3 4 5
// 0 1 -1 2 -2 3
// 0 1 2  3  4 5
private int enumerate(int x) {
  if (x == 0) {
    return 0;
  } else if (x > 0) {
    return (x*2)-1;
  } else {
    return -(x*2);
  }
}


public static void writeInt(int value, byte[] byteArray, int offset) {

  // Writing the integer into the byte array
  byteArray[offset+0] = (byte) (value >> 24); // Most significant byte
  byteArray[offset+1] = (byte) (value >> 16);
  byteArray[offset+2] = (byte) (value >> 8);
  byteArray[offset+3] = (byte) value; // Least significant byte
}

public static int getInt(byte[] byteArray, int offset) {

  // Reading the integer from the byte array
  return ((byteArray[offset+0] & 0xFF) << 24) |
    ((byteArray[offset+1] & 0xFF) << 16) |
    ((byteArray[offset+2] & 0xFF) << 8)  |
    ( byteArray[offset+3] & 0xFF);
}


private byte[] encodeTerrainCache(HashMap<XYCoords, byte[]> chunks) {
  HashMap<Integer, byte[]> yposToRow = new HashMap<Integer, byte[]>();
  HashMap<Integer, Integer> yposToRowSize = new HashMap<Integer, Integer>();

  // Needed for determining header size
  int maxY = 0;

  // Generate rows, put them into the yposToRow hasmap.
  // chunks.entrySet() will be in an arbritrary order so
  // we need to keep a hashset and use the ypos of the chunk
  // to access it
  for (HashMap.Entry<XYCoords, byte[]> e : chunks.entrySet()) {

    // values could be negative.
    // convert to natural numbers
    int x = enumerate(e.getKey().x);
    int y = enumerate(e.getKey().y);
    int index = x*CHUNK_BYTES_SIZE;

    // New yposToRow entry if it doesn't exist.
    // TODO: MAX_XY_LIMIT is not a good size for byte, maybe we could do some sort of cheap size calculation...?
    if (!yposToRow.containsKey(y)) {
      byte[] bytes = new byte[MAX_XY_LIMIT];
      
      //for (int i = 0; i < bytes.length; i++) {
      //  bytes[i] = -1;
      //}
      yposToRow.put(y, bytes);
    }

    // Now that we know the yposToRow entry exists we can access it
    byte[] row = yposToRow.get(y);
    byte[] chunkBytes = e.getValue();

    // Error checking
    if (chunkBytes.length != CHUNK_BYTES_SIZE) {
      // Warn
      println("Not right size");
      return null;
    }

    // copy chunk to the bytes at the correct index in the row.
    // For example if x = 1 then
    // 0000000000000000000
    // to
    // 0000000001111111111...
    for (int i = 0; i < CHUNK_BYTES_SIZE; i++) {
      row[index+i] = chunkBytes[i];
    }

    // Need actual size of row.
    // Remember the TODO I put up there?
    // Yeah, it's hard to decide on a size because we don't know the size until the row is filled.
    //
    // Also, if you're confused, remember, let's say we only have one chunk at x pos 10
    // Data would look something like this:
    // 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111
    // The whole point of this is it's like an array where we access it at an index. Meaning you can access
    // the 1's by going to chunk 10 in the bytes.
    if (yposToRowSize.containsKey(y)) {
      yposToRowSize.put(y, max(yposToRowSize.get(y), index+CHUNK_BYTES_SIZE));
    } else {
      yposToRowSize.put(y, index+CHUNK_BYTES_SIZE);
    }

    if (y > maxY) maxY = y;
  }
  maxY++;

  // Next step: find the row indicies.
  HashMap<Integer, Integer> yposToRowIndex = new HashMap<Integer, Integer>();

  // Calculate total size of byte block.
  int totalSize = 0;
  for (int size : yposToRowSize.values()) {
    totalSize += size;
  }

  // In the size of bytes we define here, we add a little more to add space for header info, i.e. version, length, pointers to rows.
  // TODO: If you need an extra pointer for terrain objects, change *2 to *3.
  int headerSize = maxY*Float.BYTES*2 + Float.BYTES*2;  // one for version, one for headersize.
  byte[] bytes = new byte[totalSize + headerSize];

  // Now copy the rows to the byte block and get the indicies of each row.
  {
    // Start just after header.
    int i = headerSize;

    for (HashMap.Entry<Integer, byte[]> e : yposToRow.entrySet()) {
      int y = e.getKey();
      byte[] row = e.getValue();
      // Get the index here.
      yposToRowIndex.put(y, i);
      // Now copy data from the row
      for (int j = 0; j < yposToRowSize.get(y); j++) {
        bytes[i++] = row[j];
      }
    }
  }

  // Final step: header and row indices.
  {
    // Write version
    writeInt(TERRAIN_CACHE_VERSION, bytes, 0);
    writeInt(headerSize, bytes, 4);
    // Start after version
    // TODO: terrain objects, if you are adding that, change this to 12.
    int i = 8;
    // Need to go from 0 to maxY and do this whole weird containsKey thing because remember that some y rows might simply not exist.
    // Also remember y has already been denumerated.
    for (int y = 0; y < maxY; y++) {
      if (yposToRowIndex.containsKey(y)) {
        // Dont need to add headerSize because i = headerSize when this was set.
        writeInt(yposToRowIndex.get(y), bytes, i);
        writeInt(yposToRowSize.get(y), bytes, i+4);
      } else {
        // -1 indicates no row.
        writeInt(-1, bytes, i);
        writeInt(-1, bytes, i+4);
      }
      i+=8;
    }
  }


  return bytes;
}




private HashMap<XYCoords, byte[]> decodeTerrainCache(byte[] bytes) {
  HashMap<XYCoords, byte[]> chunks = new HashMap<XYCoords, byte[]>();
  chunkCacheBlock = bytes;

  // get header info
  int version = getInt(bytes, 0);
  int headerSize = getInt(bytes, 4);

  if (version != TERRAIN_CACHE_VERSION) {
    // TODO: error handling code here.
    return null;
  }

  // converted ypos
  rowPointers = new HashMap<Integer, Integer>();
  rowLengths  = new HashMap<Integer, Integer>();

  // Get the pointers to each row.
  // TODO: change to 12 if you need an extra pointer.

  {
    int y = 0;
    for (int i = 8; i < headerSize; i+=8) {
      int ptr = getInt(bytes, i);
      if (ptr != -1) {
        rowPointers.put(denumerate(y), ptr);
        rowLengths.put(denumerate(y), getInt(bytes, i+4));
      }
      y++;
    }
  }

  for (int y = -MAX_XY_LIMIT; y < MAX_XY_LIMIT; y++) {
    for (int x = -MAX_XY_LIMIT; x < MAX_XY_LIMIT; x++) {
      byte[] chunk = getChunkCache(x, y);
      if (chunk != null) {
        chunks.put(new XYCoords(x, y), chunk);
      }
    }
  }


  return chunks;
}



private byte[] getChunkCache(int x, int y) {
  byte[] bytes = new byte[CHUNK_BYTES_SIZE];
  if (!rowPointers.containsKey(y)) {
    return null;
  }
  int rowPointer = rowPointers.get(y);

  int xindex = enumerate(x)*CHUNK_BYTES_SIZE;
   //|| rowPointer+xindex+CHUNK_BYTES_SIZE > chunkCacheBlock.length
  if (xindex >= rowLengths.get(y)) {
    return null;
  }

  boolean missingData = true;
  for (int i = 0; i < CHUNK_BYTES_SIZE; i++) {
    byte b = chunkCacheBlock[rowPointer+xindex+i];
    if (b != 0) missingData = false;
    bytes[i] = b;
  }
  if (missingData) return null;
  return bytes;
}





void setup() {
  HashMap<XYCoords, byte[]> chunks = new HashMap<XYCoords, byte[]>();
  for (int y = -4; y < 4; y++) {
    for (int x = -4; x < 4; x++) {
      byte[] row = {0, 1, 2, 3, 4, 5, 6, 7};
      chunks.put(new XYCoords(x, y), row);
    }
  }

  byte[] asdf = {69, 69, 69, 69, 69, 69, 69, 69};
  chunks.put(new XYCoords(-10, 10), asdf);

  println("Chunk set: ");
  for (HashMap.Entry<XYCoords, byte[]> e : chunks.entrySet()) {
    print("("+e.getKey().x+","+e.getKey().y+"): ");
    byte[] rrr = e.getValue();
    for (int i = 0; i < rrr.length; i++) {
      print(rrr[i]+" ");
    }
    println();
  }

  byte[] bytes = encodeTerrainCache(chunks);

  HashMap<XYCoords, byte[]> decodedChunks = decodeTerrainCache(bytes);

  println("Decoded chunk set: ");
  for (HashMap.Entry<XYCoords, byte[]> e : decodedChunks.entrySet()) {
    print("("+e.getKey().x+","+e.getKey().y+"): ");
    byte[] rrr = e.getValue();
    for (int i = 0; i < rrr.length; i++) {
      print(rrr[i]+" ");
    }
    println();
  }




  //for (int i = 0; i < bytes.length; i++) {
  //  if (i % 8 == 0) print(") (");
  //  print(bytes[i]+" ");
  //  if (i % 50 == 49) {
  //    println();
  //  }
  //}


  exit();
}
