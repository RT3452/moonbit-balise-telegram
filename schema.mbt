///|
/// Runtime field schema for inspectors and future rule-driven decoders.
pub struct FieldSchema {
  name : String
  offset : Int
  width : Int
  repeated : Bool
}

///|
pub struct PacketSchema {
  id : Int
  name : String
  fields : Array[FieldSchema]
}

///|
fn field(
  name : String,
  offset : Int,
  width : Int,
  repeated : Bool,
) -> FieldSchema {
  { name, offset, width, repeated }
}

///|
/// Return the implemented core field map, including the common envelope.
pub fn packet_schema(id : Int) -> PacketSchema {
  let common = [
    field("NID_PACKET", 0, 8, false),
    field("Q_DIR", 8, 2, false),
    field("L_PACKET", 10, 13, false),
  ]
  match id {
    5 => {
      let fields = common.copy()
      fields.push(field("Q_SCALE", 23, 2, false))
      fields.push(field("N_ITER", 25, 5, false))
      fields.push(field("D_LINK", 30, 15, true))
      fields.push(field("NID_C", 45, 10, true))
      fields.push(field("NID_BG", 55, 14, true))
      fields.push(field("Q_LINKORIENTATION", 69, 1, true))
      fields.push(field("Q_LINKREACTION", 70, 2, true))
      fields.push(field("Q_LOCACC", 72, 6, true))
      { id: 5, name: "Linking", fields }
    }
    12 => {
      let fields = common.copy()
      fields.push(field("Q_SCALE", 23, 2, false))
      fields.push(field("N_ITER", 25, 5, false))
      fields.push(field("D_SECTION", 30, 15, true))
      fields.push(field("V_MAIN", 45, 7, true))
      fields.push(field("V_LOA", 52, 7, true))
      { id: 12, name: "Movement Authority", fields }
    }
    21 => {
      let fields = common.copy()
      fields.push(field("Q_SCALE", 23, 2, false))
      fields.push(field("N_ITER", 25, 5, false))
      fields.push(field("D_GRADIENT", 30, 15, true))
      fields.push(field("Q_GDIR", 45, 1, true))
      fields.push(field("G_A", 46, 8, true))
      { id: 21, name: "Gradient", fields }
    }
    27 => {
      let fields = common.copy()
      fields.push(field("Q_SCALE", 23, 2, false))
      fields.push(field("Q_FRONT", 25, 1, false))
      fields.push(field("N_ITER", 26, 5, false))
      fields.push(field("D_STATIC", 31, 15, true))
      fields.push(field("V_STATIC", 46, 7, true))
      fields.push(field("Q_DIFF", 53, 2, true))
      { id: 27, name: "Static Speed", fields }
    }
    other => { id: other, name: "Unknown", fields: common }
  }
}

///|
pub fn schema_field(schema : PacketSchema, name : String) -> FieldSchema? {
  for item in schema.fields {
    if item.name == name {
      return Some(item)
    }
  }
  None
}

///|
pub fn schema_width(schema : PacketSchema) -> Int {
  let mut width = 0
  for item in schema.fields {
    let end = item.offset + item.width
    if end > width {
      width = end
    }
  }
  width
}

///|
pub fn schema_field_end(schema : PacketSchema, name : String) -> Int? {
  match schema_field(schema, name) {
    Some(item) => Some(item.offset + item.width)
    None => None
  }
}

///|
pub fn schema_has_field(schema : PacketSchema, name : String) -> Bool {
  match schema_field(schema, name) {
    Some(_) => true
    None => false
  }
}

///|
/// Check a decoded integer against a schema field width.
pub fn schema_value_valid(
  schema : PacketSchema,
  name : String,
  value : Int,
) -> Bool {
  match schema_field(schema, name) {
    None => false
    Some(item) => value >= 0 && value < 1 << item.width
  }
}

///|
/// Count fields which belong to repeated sections.
pub fn schema_repeated_count(schema : PacketSchema) -> Int {
  let mut count = 0
  for item in schema.fields {
    if item.repeated {
      count = count + 1
    }
  }
  count
}

///|
pub fn schema_summary(schema : PacketSchema) -> String {
  let mut result = schema.name + "(" + schema.id.to_string() + ") fields="
  result = result + schema.fields.length().to_string()
  result = result + " core_width=" + schema_width(schema).to_string()
  result
}

///|
/// Build a mask in the same MSB-first coordinate system as BitVector.
pub fn schema_mask(schema : PacketSchema, name : String) -> BitVector? {
  let item = match schema_field(schema, name) {
    Some(value) => value
    None => return None
  }
  let bits = BitVector::from_array([false].repeat(item.offset + item.width))
  let mut index = item.offset
  while index < item.offset + item.width {
    bits.bits[index] = true
    index = index + 1
  }
  Some(bits)
}
