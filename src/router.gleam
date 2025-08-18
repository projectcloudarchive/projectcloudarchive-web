import lustre/attribute

pub type Route {
  Index
  About
  AllDolls
  DollPage(String)
  NotFound
}

// Server-side links için href attribute
pub fn href(route: Route) -> attribute.Attribute(msg) {
  let url = case route {
    Index -> "/"
    About -> "/about"
    AllDolls -> "/list/dolls"
    DollPage(id) -> "/dolls/" <> id
    NotFound -> "/404"
  }

  attribute.href(url)
}
