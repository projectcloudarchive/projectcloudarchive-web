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
    skin_live2d_url: Option(String),
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

pub type Interaction {
  Interaction(
    skin_id: String,
    doll_id: String,
    interaction_id: String,
    interaction_video: String,
  )
}

pub type Model {
  Model(
    doll: Option(Doll),
    skins: List(Skin),
    selected_skin: Option(Skin),
    loading: Bool,
    error: Option(String),
    doll_id: String,
    selected_skin_id: Option(String),
    interaction_mode: Bool,
    live2d_mode: Bool,
  )
}

///
/// Messages
///
pub type Msg {
  SelectSkin(Skin)
  ToggleInteraction
  ToggleLive2D
}

///
/// UPDATE
///
pub fn update(model: Model, msg: Msg) -> Model {
  case msg {
    SelectSkin(skin) -> Model(..model, selected_skin: option.Some(skin))
    ToggleInteraction ->
      Model(..model, interaction_mode: !model.interaction_mode)
    ToggleLive2D -> Model(..model, live2d_mode: !model.live2d_mode)
  }
}

///
/// INIT - URL Query Parameter
///
pub fn init(
  doll_id: String,
  selected_skin_id: Option(String),
  interaction: Bool,
  live2d_mode: Bool,
) -> Model {
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

  let selected_skin = case selected_skin_id {
    option.Some(skin_id) -> {
      case list.find(skins, fn(skin) { skin.skin_id == skin_id }) {
        Ok(found_skin) -> option.Some(found_skin)
        Error(_) -> {
          case skins {
            [first, ..] -> option.Some(first)
            [] -> option.None
          }
        }
      }
    }
    option.None -> {
      case skins {
        [first, ..] -> option.Some(first)
        [] -> option.None
      }
    }
  }

  Model(
    doll: doll,
    skins: skins,
    selected_skin: selected_skin,
    loading: False,
    error: option.None,
    doll_id: doll_id,
    selected_skin_id: selected_skin_id,
    interaction_mode: interaction,
    live2d_mode: live2d_mode,
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
  use skin_live2d_url <- decode.field(
    "skin_live2d_url",
    decode.optional(decode.string),
  )

  decode.success(Skin(
    skin_id:,
    doll_id:,
    skin_name:,
    skin_alt:,
    skin_description:,
    skin_url:,
    skin_live2d_url:,
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
/// FETCH (Easiest way to do this)
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
/// Helper function to build URLs
///
fn build_skin_url(doll_id: String, skin_id: String, use_query: Bool) -> String {
  case use_query {
    True -> "/dolls/" <> doll_id <> "?skin=" <> skin_id
    False -> "/dolls/" <> doll_id <> "/skins/" <> skin_id
  }
}

fn build_skin_interaction_url(
  doll_id: String,
  skin_id: String,
  interaction_mode: Bool,
) -> String {
  "/dolls/"
  <> doll_id
  <> "?skin="
  <> skin_id
  <> "&interaction="
  <> case interaction_mode {
    True -> "false"
    False -> "true"
  }
}

fn build_live_2d_url(
  doll_id: String,
  skin_id: String,
  live2d_mode: Bool,
) -> String {
  "/dolls/"
  <> doll_id
  <> "?skin="
  <> skin_id
  <> "&live2d="
  <> case live2d_mode {
    True -> "false"
    False -> "true"
  }
}

///
/// VIEW
/// 
pub fn view(model: Model) -> Element(Msg) {
  html.div([a.class("min-h-screen w-[1700px] mx-auto")], [
    //
    // Error State
    //
    case model.error {
      option.Some(err) -> {
        html.div([a.class("text-center text-red-500 text-xl p-4")], [
          text(err),
        ])
      }
      option.None -> html.div([], [])
    },

    //
    // Loading State
    //
    case model.loading {
      True -> {
        html.div([a.class("text-center text-gray-400 text-xl p-4")], [
          text("Loading..."),
        ])
      }

      False -> {
        case model.doll {
          option.Some(doll) -> {
            html.div([a.class("p-6")], [
              //
              // Doll Info
              //
              html.div(
                [a.class("bg-[#705131]/10 rounded-lg p-6 mb-6 text-white")],
                [
                  html.div([a.class("flex items-center gap-4")], [
                    html.img([
                      a.class("w-24 h-24 rounded-lg object-cover"),
                      a.src(option.unwrap(doll.avatar, "")),
                      a.alt(doll.name),
                    ]),
                    html.div([], [
                      html.h1([a.class("text-3xl font-bold mb-2")], [
                        text(doll.name),
                      ]),
                      html.p([a.class("text-gray-300 text-lg")], [
                        text(option.unwrap(
                          doll.description,
                          "No description available",
                        )),
                      ]),
                      html.div(
                        [a.class("flex gap-4 mt-2 text-sm text-gray-400")],
                        [
                          case doll.company {
                            option.Some(company) ->
                              html.span([], [text("Company: " <> company)])
                            option.None -> html.span([], [])
                          },
                          case doll.class {
                            option.Some(class) ->
                              html.span([], [text("Class: " <> class)])
                            option.None -> html.span([], [])
                          },
                        ],
                      ),
                    ]),
                  ]),
                ],
              ),

              html.div([a.class("relative flex gap-6")], [
                html.div([a.class("flex-1")], [
                  case model.selected_skin {
                    option.Some(skin) -> {
                      html.div(
                        [a.class("bg-[#705131]/10 rounded-lg p-6 text-white")],
                        [
                          html.div([a.class("relative text-center")], [
                            case model.live2d_mode {
                              True -> {
                                html.div(
                                  [
                                    a.class(
                                      "relative flex flex-col items-center justify-center w-[1200px] mx-auto",
                                    ),
                                  ],
                                  [
                                    html.img([
                                      a.src(option.unwrap(
                                        skin.skin_live2d_url,
                                        "",
                                      )),
                                      a.alt(option.unwrap(skin.skin_alt, "")),
                                      a.class(
                                        "w-[700px] h-[700px] mb-4 select-none",
                                      ),
                                    ]),

                                    //
                                    // Live2D button
                                    //
                                    html.div(
                                      [
                                        a.class(
                                          "absolute bottom-20 right-20 w-40 h-8 bg-gray-400/40 rounded-full p-2 flex justify-start",
                                        ),
                                      ],
                                      [
                                        // Live2D text label
                                        html.div(
                                          [
                                            a.class(
                                              "absolute bottom-10 right-14",
                                            ),
                                          ],
                                          [text("Live2D")],
                                        ),

                                        // Live2D link button
                                        html.a(
                                          [
                                            a.href(build_live_2d_url(
                                              model.doll_id,
                                              skin.skin_id,
                                              model.live2d_mode,
                                            )),
                                            a.class(
                                              "w-20 bg-gray-400/20 rounded-full p-2",
                                            ),
                                          ],
                                          [],
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              }
                              False -> {
                                case model.interaction_mode {
                                  True -> {
                                    html.div(
                                      [a.class("relative w-[1200px] mx-auto")],
                                      [
                                        html.video(
                                          [
                                            a.class(
                                              "w-full rounded-lg mb-4 select-none",
                                            ),
                                            a.src(
                                              "https://v.animethemes.moe/BangDreamAveMujica-OP1.webm",
                                            ),
                                            a.controls(True),
                                            a.autoplay(True),
                                            a.loop(False),
                                          ],
                                          [],
                                        ),

                                        html.a(
                                          [
                                            a.href(
                                              "/dolls/"
                                              <> model.doll_id
                                              <> "?skin="
                                              <> skin.skin_id,
                                            ),
                                            a.class(
                                              "absolute top-4 right-4 bg-gray-600/20 text-white px-3 py-2 rounded hover:bg-gray-700 transition",
                                            ),
                                          ],
                                          [text("<--")],
                                        ),
                                      ],
                                    )
                                  }
                                  False -> {
                                    html.div(
                                      [
                                        a.class(
                                          "flex flex-col items-center justify-center",
                                        ),
                                      ],
                                      [
                                        html.img([
                                          a.src(skin.skin_url),
                                          a.class(
                                            "w-[700px] h-[700px] mb-4 select-none",
                                          ),
                                        ]),

                                        //
                                        // Live2D Button
                                        //
                                        html.div(
                                          [
                                            a.class(
                                              "absolute mb-5 bottom-20 right-20 w-40 h-5 bg-gray-400/20 rounded-full p-2 flex justify-end",
                                            ),
                                          ],
                                          [
                                            // Live2D text label
                                            html.div(
                                              [
                                                a.class(
                                                  "absolute bottom-7 font-bold right-14 items-center justify-center",
                                                ),
                                              ],
                                              [text("Live2D")],
                                            ),

                                            // Live2D link button
                                            html.a(
                                              [
                                                a.href(build_live_2d_url(
                                                  model.doll_id,
                                                  skin.skin_id,
                                                  model.live2d_mode,
                                                )),
                                                a.class(
                                                  "w-20 bg-yellow-400 rounded-full",
                                                ),
                                              ],
                                              [],
                                            ),
                                          ],
                                        ),

                                        //
                                        // Interaction button
                                        //
                                        html.a(
                                          [
                                            a.href(build_skin_interaction_url(
                                              model.doll_id,
                                              skin.skin_id,
                                              model.interaction_mode,
                                            )),
                                            a.class(
                                              "absolute  mb-5 rounded-full bottom-20 right-0 bg-gray-600/40 p-4 w-14 h-14 flex items-center justify-center text-white font-bold text-lg hover:bg-gray-500/60 transition",
                                            ),
                                          ],
                                          [text("Ins")],
                                        ),

                                        html.p(
                                          [
                                            a.class(
                                              "absolute  bottom-0 left-0 text-left text-white bg-gray-600/20 p-4 rounded w-full",
                                            ),
                                          ],
                                          [
                                            text(option.unwrap(
                                              skin.skin_description,
                                              "",
                                            )),
                                          ],
                                        ),
                                      ],
                                    )
                                  }
                                }
                              }
                            },
                          ]),
                        ],
                      )
                    }
                    option.None -> {
                      html.div(
                        [
                          a.class(
                            "bg-[#705131]/10 rounded-lg p-6 text-white text-center",
                          ),
                        ],
                        [
                          html.p([a.class("text-gray-400 text-lg")], [
                            text("No skin selected"),
                          ]),
                        ],
                      )
                    }
                  },
                ]),

                html.div([a.class("w-80")], [
                  html.div(
                    [a.class("bg-[#705131]/10 rounded-lg p-6 text-white")],
                    [
                      html.h2([a.class("text-xl font-bold mb-4")], [
                        text(
                          "Available Skins ("
                          <> int.to_string(list.length(model.skins))
                          <> ")",
                        ),
                      ]),
                      case model.skins {
                        [] -> {
                          html.p([a.class("text-gray-400 text-center")], [
                            text("No skins available"),
                          ])
                        }
                        skins -> {
                          html.div(
                            [a.class("space-y-3 max-h-96 overflow-y-auto")],
                            list.map(skins, fn(skin) {
                              let is_selected = case model.selected_skin {
                                option.Some(selected) ->
                                  selected.skin_id == skin.skin_id
                                option.None -> False
                              }

                              let link_class = case is_selected {
                                True ->
                                  "block w-full p-3 rounded-lg bg-[#705131]/10 hover:bg-[#705131]/40 border-l-4 border-[#705131] transition text-left text-white no-underline"
                                False ->
                                  "block w-full p-3 rounded-lg bg-[#705131]/40 hover:bg-[#705131]/10 transition-colors text-left text-white no-underline hover:text-white"
                              }

                              html.a(
                                [
                                  a.href(build_skin_url(
                                    model.doll_id,
                                    skin.skin_id,
                                    True,
                                  )),
                                  a.class(link_class),
                                ],
                                [
                                  html.div(
                                    [a.class("flex items-center gap-3")],
                                    [
                                      html.img([
                                        a.class(
                                          "w-12 h-12 rounded object-cover",
                                        ),
                                        a.src(skin.skin_url),
                                        a.alt(skin.skin_name),
                                      ]),
                                      html.div([], [
                                        html.div([a.class("font-medium")], [
                                          text(skin.skin_name),
                                        ]),
                                        case is_selected {
                                          True ->
                                            html.div(
                                              [a.class("text-sm text-blue-200")],
                                              [text("Selected")],
                                            )
                                          False -> html.div([], [])
                                        },
                                      ]),
                                    ],
                                  ),
                                ],
                              )
                            }),
                          )
                        }
                      },
                    ],
                  ),
                ]),
              ]),
            ])
          }
          option.None -> {
            html.div([a.class("text-center text-gray-400 text-xl p-4")], [
              text("Doll not found"),
            ])
          }
        }
      }
    },
  ])
}
