import lustre/attribute as a
import lustre/element.{type Element, text}
import lustre/element/html
import router.{type Route, href}

pub fn footer_view(current_route: Route) -> Element(msg) {
  html.footer(
    [
      a.class("bg-[#212121] w-full h-25 shadow-md"),
    ],
    [
      html.div(
        [
          a.class(
            "flex justify-between align-center items-center p-6 gap-4 text-white",
          ),
        ],
        [
          html.a(
            [
              a.class(
                "hover:text-[#FFBD4F] text-md hover:cursor-pointer hover:underline",
              ),
              href(router.About),
            ],
            [
              text("About"),
            ],
          ),
          html.div(
            [
              a.class("text-white flex justify-between items-center gap-4"),
            ],
            [
              text("Powered By:"),
              html.img([
                a.src(
                  "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Gleam_Lucy.svg/1200px-Gleam_Lucy.svg.png",
                ),
                a.class("w-10 h-10 hover:cursor-pointer"),
                a.alt("Gleam"),
              ]),
              html.img([
                a.src(
                  "https://avatars.githubusercontent.com/u/145234907?s=200&v=4",
                ),
                a.class("w-10 h-10 hover:cursor-pointer"),
                a.alt("Lustre"),
              ]),
              html.img([
                a.src(
                  "https://avatars.githubusercontent.com/u/151276991?s=200&v=4",
                ),
                a.class("w-10 h-10 hover:cursor-pointer"),
                a.alt("Wisp"),
              ]),
              html.img([
                a.src(
                  "https://pngate.com/wp-content/uploads/2025/05/tailwindcss-tailwind-css-logo-blue-wave-symbol-design-1.png",
                ),
                a.class("w-10 h-10 hover:cursor-pointer"),
                a.alt("TailwindCSS"),
              ]),
            ],
          ),

          html.a(
            [
              a.class("bg-[#ffffff] rounded-full p-1"),
              a.href("https://github.com/projectcloudarchive"),
              a.target("_blank"),
            ],
            [
              html.img([
                a.src("https://simpleicons.org/icons/github.svg"),
                a.class("w-10 h-10"),
                a.alt("GitHub"),
              ]),
            ],
          ),
        ],
      ),
    ],
  )
}
