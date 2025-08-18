import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/int
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
/// FETCH
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
  html.div([a.class("min-h-screen")], [
    html.div([a.class("container mx-auto px-4 py-8")], [
      // Error State
      case model.error {
        option.Some(msg) ->
          html.div(
            [
              a.class("mb-6 p-4 border border-red-700 rounded-lg text-red-200"),
            ],
            [
              html.div([a.class("flex items-center gap-2")], [
                html.div([a.class("w-5 h-5 bg-red-500 rounded-full")], []),
                html.span([a.class("font-semibold")], [text("Error")]),
              ]),
              html.p([a.class("mt-2 text-sm")], [text(msg)]),
            ],
          )
        option.None -> html.div([], [])
      },

      // Loading State
      case model.loading {
        True ->
          html.div([a.class("flex items-center justify-center h-96")], [
            html.div(
              [
                a.class(
                  "animate-spin w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full",
                ),
              ],
              [],
            ),
            html.p([a.class("ml-4 text-gray-400")], [text("Loading...")]),
          ])
        False ->
          case model.doll {
            option.Some(doll) ->
              html.div([a.class("space-y-8")], [
                // Doll Header
                html.div([a.class("text-center")], [
                  html.h1([a.class("text-4xl font-bold text-white mb-2")], [
                    text(doll.name),
                  ]),
                  case doll.description {
                    option.Some(desc) ->
                      html.p(
                        [a.class("text-gray-400 text-lg max-w-2xl mx-auto")],
                        [text(desc)],
                      )
                    option.None -> html.div([], [])
                  },
                ]),

                // Main Content - Video + Skins
                html.div(
                  [a.class("grid grid-cols-1 xl:grid-cols-2 gap-8 items-start")],
                  [
                    // Video Section
                    html.div([a.class("space-y-4")], [
                      html.h2([a.class("text-2xl font-semibold text-white")], [
                        text("Preview"),
                      ]),
                      html.div(
                        [
                          a.class(
                            "aspect-video bg-gray-800 border-2 border-gray-700 rounded-lg overflow-hidden shadow-lg",
                          ),
                        ],
                        [
                          html.video(
                            [
                              a.src(
                                "https://v.animethemes.moe/FateZero-OP1.webm",
                              ),
                              a.class("w-full h-full object-cover"),
                              a.attribute("controls", ""),
                              a.attribute("preload", "metadata"),
                            ],
                            [],
                          ),
                        ],
                      ),
                    ]),

                    // Skins Section
                    html.div([a.class("space-y-4")], [
                      html.div([a.class("flex items-center justify-between")], [
                        html.h2([a.class("text-2xl font-semibold text-white")], [
                          text("Skins"),
                        ]),
                        html.span([a.class("text-sm text-gray-400")], [
                          text(
                            int.to_string(list.length(model.skins))
                            <> " skins available",
                          ),
                        ]),
                      ]),

                      case list.is_empty(model.skins) {
                        True ->
                          html.div(
                            [a.class("text-center py-12 text-gray-500")],
                            [
                              html.p([a.class("text-lg")], [
                                text("No skins available"),
                              ]),
                            ],
                          )
                        False ->
                          html.div(
                            [
                              a.class(
                                "flex overflow-x-auto gap-4 pb-4 scrollbar-thin scrollbar-track-gray-800 scrollbar-thumb-gray-600",
                              ),
                            ],
                            list.map(model.skins, fn(skin: Skin) -> Element(a) {
                              html.div(
                                [
                                  a.class(
                                    "flex-shrink-0 w-64 bg-gray-800/50 border border-gray-600 rounded-lg overflow-hidden hover:border-yellow-400 hover:shadow-lg transition-all duration-300 cursor-pointer group",
                                  ),
                                ],
                                [
                                  // Skin Image
                                  html.div(
                                    [a.class("relative overflow-hidden")],
                                    [
                                      html.img([
                                        a.src(skin.skin_url),
                                        a.class(
                                          "w-full h-80 object-cover group-hover:scale-105 transition-transform duration-300",
                                        ),
                                      ]),
                                      html.div(
                                        [
                                          a.class(
                                            "absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors duration-300",
                                          ),
                                        ],
                                        [],
                                      ),
                                    ],
                                  ),

                                  //
                                  // Skin Info
                                  //
                                  html.div([a.class("p-4")], [
                                    html.h3(
                                      [
                                        a.class(
                                          "font-semibold text-white mb-2 text-lg group-hover:text-yellow-400 transition-colors",
                                        ),
                                      ],
                                      [text(skin.skin_name)],
                                    ),

                                    case skin.skin_description {
                                      option.Some(desc) ->
                                        html.p(
                                          [
                                            a.class(
                                              "text-gray-400 text-sm line-clamp-2",
                                            ),
                                          ],
                                          [text(desc)],
                                        )
                                      option.None ->
                                        html.p(
                                          [
                                            a.class(
                                              "text-gray-500 text-sm italic",
                                            ),
                                          ],
                                          [text("No description available")],
                                        )
                                    },
                                    case skin.skin_alt {
                                      option.Some(alt) ->
                                        html.div(
                                          [
                                            a.class(
                                              "mt-3 pt-3 border-t border-gray-700",
                                            ),
                                          ],
                                          [
                                            html.span(
                                              [a.class("text-xs text-gray-500")],
                                              [text("Alt: " <> alt)],
                                            ),
                                          ],
                                        )
                                      option.None -> html.div([], [])
                                    },
                                  ]),
                                ],
                              )
                            }),
                          )
                      },
                    ]),
                  ],
                ),
              ])

            option.None ->
              html.div([a.class("text-center py-20")], [
                html.div([a.class("max-w-md mx-auto")], [
                  html.div(
                    [
                      a.class(
                        "w-20 h-20 bg-gray-700 rounded-full mx-auto mb-4 flex items-center justify-center",
                      ),
                    ],
                    [
                      html.span([a.class("text-3xl text-gray-500")], [text("?")]),
                    ],
                  ),
                  html.h2([a.class("text-2xl font-semibold text-white mb-2")], [
                    text("Doll Not Found"),
                  ]),
                  html.p([a.class("text-gray-400 mb-6")], [
                    text(
                      "The doll you're looking for doesn't exist or has been removed.",
                    ),
                  ]),
                  html.a(
                    [
                      a.href("/dolls"),
                      a.class(
                        "inline-block px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors",
                      ),
                    ],
                    [text("Browse All Dolls")],
                  ),
                ]),
              ])
          }
      },
    ]),
  ])
}
