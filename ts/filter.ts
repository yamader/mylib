const filter = (keys: String[], map: Record<String, any>) =>
  keys.reduce((obj, key) => ({ ...obj, [key]: map[key] }), {})
