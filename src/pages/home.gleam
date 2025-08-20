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

///
/// MODEL -----------------------------------------------------------------------
///
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

pub fn init(_) -> #(Model, Nil) {
  let #(dolls, error) = case fetch_dolls_from_backend() {
    Ok(dolls) -> #(dolls, option.None)
    Error(err) -> #([], option.Some(err))
  }

  #(Model(dolls: dolls, loading: False, error: error), Nil)
}

///
/// BACKEND DATA -------------------------------------------------------
///
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

fn dolls_decoder() -> decode.Decoder(List(Doll)) {
  decode.list(doll_decoder())
}

//
// Fetch (a Strange way to do this)
// 
pub fn fetch_dolls_from_backend() -> Result(List(Doll), String) {
  case request.to("http://127.0.0.1:8000/dolls/") {
    Error(_) -> Error("Invalid URL")
    Ok(req) -> {
      case httpc.send(req) {
        Error(_) -> Error("Failed to connect to backend service")
        Ok(response) -> {
          case response.status {
            200 -> parse_dolls_response(response.body)
            404 -> Error("Dolls endpoint not found")
            500 -> Error("Backend server error")
            _ -> Error("Unexpected response from server")
          }
        }
      }
    }
  }
}

fn parse_dolls_response(body: String) -> Result(List(Doll), String) {
  case json.parse(body, using: decode.dynamic) {
    Error(_) -> Error("Invalid JSON response from server")
    Ok(dynamic_data) ->
      case decode.run(dynamic_data, dolls_decoder()) {
        Error(_) -> Error("Failed to parse doll data from server")
        Ok(dolls) -> Ok(dolls)
      }
  }
}

///
/// VIEW ------------------------------------------------------------------------
///
fn render_doll_card(doll: Doll) -> Element(msg) {
  let description = option.unwrap(doll.description, "No description available")
  let typ = option.unwrap(doll.typ, "Unknown")
  let class = option.unwrap(doll.class, "Unknown")
  let avatar = option.unwrap(doll.avatar, "")

  html.a(
    [
      a.class(
        "relative rounded-lg w-full bg-[#705131]/10 p-4 m-2 hover:cursor-pointer hover:shadow-lg hover:bg-[#705131]/30 transition-all duration-200 border border-[#705131]/20",
      ),
      router.href(router.DollPage(doll.id)),
    ],
    [
      // Avatar image
      case avatar {
        "" ->
          html.div(
            [
              a.class(
                "w-full h-40 bg-gray-600/50 rounded-md flex items-center justify-center mb-4 border border-gray-600",
              ),
            ],
            [
              html.div([a.class("text-gray-400 text-center")], [
                text("No Image Available"),
              ]),
            ],
          )
        _ ->
          html.div([a.class("relative mb-4")], [
            html.img([
              a.src(avatar),
              a.attribute("alt", doll.name <> " avatar"),
              a.class("w-full h-40 rounded-md object-cover"),
              a.attribute("loading", "lazy"),
              a.attribute(
                "onerror",
                "this.parentElement.innerHTML='<div class=\"w-full h-40 bg-gray-600/50 rounded-md flex items-center justify-center border border-gray-600\"><span class=\"text-gray-400\">Image Load Failed</span></div>'",
              ),
            ]),
          ])
      },
      //
      // Doll info
      //
      html.div([a.class("space-y-2")], [
        html.h3([a.class("text-white font-semibold text-lg truncate")], [
          text(doll.name),
        ]),
        html.p([a.class("text-gray-300 text-sm line-clamp-2 min-h-[2.5rem]")], [
          text(description),
        ]),
        html.div([a.class("flex justify-between mt-3 text-xs")], [
          html.span(
            [a.class("text-blue-400 bg-blue-400/20 px-2 py-1 rounded")],
            [text("Type: " <> typ)],
          ),
          html.span(
            [a.class("text-green-400 bg-green-400/20 px-2 py-1 rounded")],
            [text("Class: " <> class)],
          ),
        ]),
      ]),
    ],
  )
}

fn render_error_state(error: String) -> Element(msg) {
  html.div([a.class("max-w-md mx-auto mt-20 text-center")], [
    html.div(
      [a.class("bg-red-500/20 border border-red-500/30 rounded-lg p-6")],
      [
        html.div([a.class("text-red-400 text-4xl mb-4")], []),
        html.h2([a.class("text-red-400 font-bold text-xl mb-2")], [
          text("Connection Error"),
        ]),
        html.p([a.class("text-red-300 text-sm mb-4")], [text(error)]),
      ],
    ),
  ])
}

fn render_empty_state() -> Element(msg) {
  html.div([a.class("max-w-md mx-auto mt-20 text-center")], [
    html.div(
      [a.class("bg-gray-500/20 border border-gray-500/30 rounded-lg p-6")],
      [
        html.div([a.class("text-gray-400 text-4xl mb-4")], []),
        html.h2([a.class("text-gray-300 font-bold text-xl mb-2")], [
          text("No Dolls Found"),
        ]),
        html.p([a.class("text-gray-400 text-sm")], [
          text("The archive appears to be empty. Please check back later."),
        ]),
      ],
    ),
  ])
}

pub fn view(model: Model) -> Element(msg) {
  html.div([a.class("min-h-screen w-full p-4 md:p-8")], [
    html.div([a.class("container mx-auto max-w-7xl")], [
      html.div([a.class("text-center mb-12")], [
        html.h1([a.class("text-white font-bold text-3xl md:text-4xl mb-4")], [
          text("Project Neural Cloud: Archive"),
        ]),
        html.p([a.class("text-gray-400 text-lg")], [
          text("An archive for Project Neural Cloud."),
        ]),
      ]),

      case model.error {
        option.Some(error_msg) -> render_error_state(error_msg)
        option.None -> {
          case list.length(model.dolls) {
            0 -> render_empty_state()
            _ ->
              html.div([a.class("space-y-8")], [
                html.div([a.class("text-center mb-8 gap-8 ")], [
                  html.span(
                    [
                      a.class(
                        "bg-[#705131]/20 text-[#705131] px-4 py-2 rounded text-sm font-semibold",
                      ),
                    ],
                    [
                      text(
                        string.inspect(list.length(model.dolls))
                        <> "+"
                        <> " DOLLS",
                      ),
                    ],
                  ),
                ]),

                // Grid
                html.div(
                  [
                    a.class(
                      "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-6 gap-6",
                    ),
                  ],
                  list.map(model.dolls, render_doll_card),
                ),
              ])
          }
        }
      },
    ]),
  ])
}
