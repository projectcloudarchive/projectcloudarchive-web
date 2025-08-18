import lustre/attribute as a
import lustre/element.{type Element, text}
import lustre/element/html
import router.{type Route, href}

pub fn header_view(current_route: Route) -> Element(msg) {
  html.header([a.class("bg-[#212121] w-full h-20 fixed z-100 shadow-md")], [
    html.div([a.class("flex justify-around items-center h-full px-24")], [
      //
      // Logo
      //
      html.div([a.class("flex items-center space-x-2")], [
        html.a([href(router.Index)], [
          html.img([
            a.src("/static/images/logo.png"),
            a.attribute("alt", "Project Neural Cloud: Archive"),
            a.class("h-14 w-14 p-1 hover:cursor-pointer"),
          ]),
        ]),
        html.span([a.class("text-white text-lg font-semibold")], [
          text("Project Neural Cloud: Archive"),
        ]),
      ]),

      //
      // Menu links
      //
      html.ul([a.class("flex space-x-4")], [
        html.li(
          [
            a.class(
              "text-white hover:text-[#FFBD4F] hover:cursor-pointer hover:underline rounded-2xl transition-all duration-200",
            ),
          ],
          [html.a([href(router.Index)], [text("Home")])],
        ),
        html.li(
          [
            a.class(
              "text-white hover:text-[#FFBD4F] hover:cursor-pointer hover:underline rounded-2xl transition-all duration-200",
            ),
          ],
          [html.a([href(router.AllDolls)], [text("Dolls")])],
        ),
      ]),
    ]),
  ])
}
