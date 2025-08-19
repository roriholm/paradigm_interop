struct Location {
  1: double latitude
  2: double longitude
  3: double altitude
}

struct Passenger {
  1: string name
  2: i32 seat_number
}

struct Tire {
  1: double pressure
  2: string position
  3: double tread_depth
}

struct Engine {
  1: string type
  2: double displacement
  3: i32 horsepower
}

struct Vehicle {
  1: string make
  2: string model
  3: i32 year
  4: Engine engine
  5: list<Tire> tires
  6: list<Passenger> passengers
  7: Location current_location
}
