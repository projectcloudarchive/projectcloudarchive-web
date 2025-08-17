import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/list
import gleam/option.{type Option}
import lustre/attribute as a
import lustre/element.{type Element, text}
import lustre/element/html

///
/// Models
///
pub type Skin {
  Skin(
    skin_id: String,
    doll_id: Option(String),
    skin_name: String,
    skin_alt: Option(String),
    skin_description: Option(String),
    skin_url: String,
  )
}

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
  Model(
    doll: Option(Doll),
    skins: List(Skin),
    loading: Bool,
    error: Option(String),
    doll_id: String,
  )
}

///
/// INIT (SSR FETCH)
///
pub fn init(doll_id: String) -> Model {
  let doll_res = fetch_doll_from_backend(doll_id)
  let skins_res = fetch_skins(doll_id)

  let doll = case doll_res {
    Ok(d) -> option.Some(d)
    Error(_) -> option.None
  }

  let skins = case skins_res {
    Ok(s) -> s
    Error(_) -> []
  }

  Model(
    doll: doll,
    skins: skins,
    loading: False,
    error: option.None,
    doll_id: doll_id,
  )
}

///
/// DECODER
///
fn skin_decoder() -> decode.Decoder(Skin) {
  use skin_id <- decode.field("skin_id", decode.string)
  use doll_id <- decode.field("doll_id", decode.optional(decode.string))
  use skin_name <- decode.field("skin_name", decode.string)
  use skin_alt <- decode.field("skin_alt", decode.optional(decode.string))
  use skin_description <- decode.field(
    "skin_description",
    decode.optional(decode.string),
  )
  use skin_url <- decode.field("skin_url", decode.string)

  decode.success(Skin(
    skin_id:,
    doll_id:,
    skin_name:,
    skin_alt:,
    skin_description:,
    skin_url:,
  ))
}

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

///
/// BACKEND FETCH
///
pub fn fetch_doll_from_backend(doll_id: String) -> Result(Doll, String) {
  case request.to("http://127.0.0.1:8000/dolls/" <> doll_id) {
    Error(_) -> Error("Invalid URL")
    Ok(req) ->
      case httpc.send(req) {
        Error(_) -> Error("Failed to fetch doll data")
        Ok(response) ->
          case json.parse(response.body, using: decode.dynamic) {
            Error(_) -> Error("Invalid JSON from backend")
            Ok(dynamic_data) ->
              case decode.run(dynamic_data, doll_decoder()) {
                Ok(doll) -> Ok(doll)
                Error(_) -> Error("Failed to decode Doll")
              }
          }
      }
  }
}

pub fn fetch_skins(doll_id: String) -> Result(List(Skin), String) {
  case request.to("http://127.0.0.1:8000/dolls/" <> doll_id <> "/skins") {
    Error(_) -> Error("Invalid URL")
    Ok(req) ->
      case httpc.send(req) {
        Error(_) -> Error("Failed to fetch skins")
        Ok(response) ->
          case json.parse(response.body, using: decode.dynamic) {
            Error(_) -> Error("Invalid JSON from backend")
            Ok(dynamic_data) ->
              case decode.run(dynamic_data, decode.list(skin_decoder())) {
                Ok(skins) -> Ok(skins)
                Error(_) -> Error("Failed to decode skins")
              }
          }
      }
  }
}

///
/// VIEW
/// 
pub fn view(model: Model) -> Element(a) {
  html.div([a.class("p-8 text-white")], [
    //
    // Error State
    //
    case model.error {
      option.Some(msg) -> html.div([], [text("Error: " <> msg)])
      option.None -> html.div([], [])
    },

    case model.doll {
      option.Some(doll) ->
        html.div([a.class("mt-6")], [
          html.h1([a.class("text-2xl font-bold")], [text(doll.name)]),
          html.p([], [text(option.unwrap(doll.description, "No description"))]),
          html.p([], [text("Type: " <> option.unwrap(doll.typ, ""))]),
          html.p([], [text("Class: " <> option.unwrap(doll.class, ""))]),
          case doll.avatar {
            option.Some(url) ->
              html.img([a.src(url), a.class("mt-4 w-60 rounded")])
            option.None -> text("No Avatar")
          },

          // SKINS
          html.div(
            [a.class("mt-8")],
            list.map(model.skins, fn(skin: Skin) -> Element(a) {
              html.div([a.class("mt-4 border p-2 rounded")], [
                html.h2([a.class("font-semibold")], [text(skin.skin_name)]),
                html.p([], [
                  text(option.unwrap(skin.skin_description, "No description")),
                ]),
                html.img([a.src(skin.skin_url), a.class("mt-2 w-40 rounded")]),
              ])
            }),
          ),
        ])
      option.None -> html.div([], [text("Doll not found.")])
    },
  ])
}
