import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/string
import lustre/attribute as a
import lustre/element.{type Element, text}
import lustre/element/html
import router

// MODELS ----------------------------------------------------------------------

pub type Doll {
  Doll(
    id: String,
    name: String,
    slug: String,
    description: Option(String),
    typ: Option(String),
    company: Option(String),
    birthday: Option(String),
    class: Option(String),
    avatar: Option(String),
  )
}

pub type Model {
  Model(dolls: List(Doll), loading: Bool, error: Option(String))
}

// INIT ------------------------------------------------------------------------

pub fn init(_) -> Model {
  let #(dolls, error) = case fetch_dolls() {
    Ok(dolls) -> #(dolls, option.None)
    Error(err) -> #([], option.Some(err))
  }

  Model(dolls: dolls, loading: False, error: error)
}

// BACKEND FETCH ---------------------------------------------------------------

fn doll_decoder() -> decode.Decoder(Doll) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use slug <- decode.field("slug", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use typ <- decode.field("typ", decode.optional(decode.string))
  use company <- decode.field("company", decode.optional(decode.string))
  use birthday <- decode.field("birthday", decode.optional(decode.string))
  use class <- decode.field("class", decode.optional(decode.string))
  use avatar <- decode.field("avatar", decode.optional(decode.string))

  decode.success(Doll(
    id:,
    name:,
    slug:,
    description:,
    typ:,
    company:,
    birthday:,
    class:,
    avatar:,
  ))
}

pub fn fetch_dolls() -> Result(List(Doll), String) {
  case request.to("http://127.0.0.1:8000/dolls/") {
    Error(_) -> Error("Invalid URL")
    Ok(req) ->
      case httpc.send(req) {
        Error(_) -> Error("Failed to connect to backend")
        Ok(response) ->
          case json.parse(response.body, using: decode.dynamic) {
            Error(_) -> Error("Invalid JSON response")
            Ok(dynamic_data) ->
              case decode.run(dynamic_data, decode.list(doll_decoder())) {
                Error(_) -> Error("Failed to parse doll data")
                Ok(dolls) -> Ok(dolls)
              }
          }
      }
  }
}

// VIEW ------------------------------------------------------------------------

fn render_doll_card(doll: Doll) -> Element(msg) {
  let description = option.unwrap(doll.description, "No description")
  let typ = option.unwrap(doll.typ, "Unknown")
  let class = option.unwrap(doll.class, "Unknown")
  let avatar = option.unwrap(doll.avatar, "")

  html.a(
    [
      a.class(
        "bg-[#705131]/10 border border-[#705131]/20 rounded-lg p-4 hover:bg-[#705131]/20 transition-colors",
      ),
      router.href(router.DollPage(doll.id)),
    ],
    [
      // Avatar
      case avatar {
        "" ->
          html.div(
            [
              a.class(
                "w-full h-40 bg-gray-600 rounded-md flex items-center justify-center mb-4",
              ),
            ],
            [
              text("No Image"),
            ],
          )
        _ ->
          html.img([
            a.src(avatar),
            a.attribute("alt", doll.name),
            a.class("w-full h-40 rounded-md object-cover mb-4"),
          ])
      },

      // Info
      html.div([], [
        html.h3([a.class("text-white font-semibold text-lg mb-2")], [
          text(doll.name),
        ]),
        html.p([a.class("text-gray-400 text-sm mb-2")], [text(description)]),
        html.div([a.class("flex justify-between text-xs text-gray-500")], [
          html.span([], [text("Type: " <> typ)]),
          html.span([], [text("Class: " <> class)]),
        ]),
      ]),
    ],
  )
}

pub fn view(model: Model) -> Element(msg) {
  html.div([a.class("min-h-screen w-full p-8")], [
    html.div([a.class("container mx-auto")], [
      html.h1([a.class("text-white font-bold text-3xl text-center mb-8")], [
        text("All Dolls"),
      ]),

      // Error handling
      case model.error {
        option.Some(error_msg) ->
          html.div([a.class("text-center text-red-500 text-xl mb-8")], [
            text("Error: " <> error_msg),
          ])
        option.None -> html.div([], [])
      },

      // Dolls grid
      case list.length(model.dolls) {
        0 ->
          html.div([a.class("text-center text-gray-400 text-xl")], [
            text("No dolls found."),
          ])
        count ->
          html.div([], [
            html.p([a.class("text-center text-gray-400 mb-6")], [
              text("Found " <> string.inspect(count) <> " dolls"),
            ]),
            html.div(
              [
                a.class(
                  "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6",
                ),
              ],
              list.map(model.dolls, render_doll_card),
            ),
          ])
      },
    ]),
  ])
}
