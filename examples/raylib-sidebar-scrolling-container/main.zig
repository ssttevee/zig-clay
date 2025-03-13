const std = @import("std");
const clay = @import("clay");

const renderer = clay.renderers.raylib;
const rl = renderer.raylib;

const font_id_body_24: usize = 0;
const font_id_body_16: usize = 1;

const color_orange: clay.Color = .rgb(225, 138, 50);
const color_blue: clay.Color = .rgb(111, 173, 162);

var profile_picture: rl.Texture2D = undefined;

inline fn raylibToClayVector2(vec: rl.Vector2) clay.Vector2 {
    return .{
        .x = vec.x,
        .y = vec.y,
    };
}

const profile_text = "Profile Page one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen";
const header_text_config: clay.TextElementConfig = .{ .font_id = 1, .font_size = 16, .text_color = .black };

fn handleHeaderButtonInteraction(element_id: clay.ElementId, pointer_data: clay.PointerData, user_data: ?*anyopaque) void {
    if (pointer_data.state == .pressed_this_frame) {
        // Do some click handling
        _ = element_id;
        _ = user_data;
    }
}

fn headerButtonStyle(hovered: bool) clay.ElementDeclaration {
    return .{
        .layout = .{ .padding = .xy(16, 8) },
        .background_color = if (hovered) color_orange else color_blue,
    };
}

// Examples of re-usable "Components"
fn renderHeaderButton(text: []const u8) void {
    clay.ui()(headerButtonStyle(clay.isHovered()))({
        clay.text(text, &header_text_config);
    });
}

const dropdown_text_item_layout: clay.LayoutConfig = .{ .padding = .xy(8, 4) };
const dropdown_text_element_config: clay.TextElementConfig = .{ .font_size = 24, .text_color = .white };

fn renderDropdownTextItem(index: usize) void {
    _ = index;
    clay.ui()(.{ .layout = dropdown_text_item_layout, .background_color = .rgb(180, 180, 180) })({
        clay.text("I'm a text field in a scroll container.", &dropdown_text_element_config);
    });
}

fn createLayout() clay.RenderCommandArray {
    return clay.layout()({
        clay.ui()(.{ .id = .id("OuterContainer"), .layout = .{ .sizing = .grow(.{}), .padding = .all(16), .child_gap = 16 }, .background_color = .rgb(200, 200, 200) })({
            clay.ui()(.{ .id = .id("SideBar"), .layout = .{ .layout_direction = .top_to_bottom, .sizing = .{ .width = .fixed(300), .height = .grow(.{}) }, .padding = .all(16), .child_gap = 16 }, .background_color = .rgb(150, 150, 255) })({
                clay.ui()(.{ .id = .id("ProfilePictureOuter"), .layout = .{ .sizing = .{ .width = .grow(.{}) }, .padding = .all(8), .child_gap = 8, .child_alignment = .center_left }, .background_color = .rgb(130, 130, 255) })({
                    clay.ui()(.{ .id = .id("ProfilePicture"), .layout = .{ .sizing = .fixed(60) }, .image = .{ .image_data = &profile_picture, .source_dimensions = .{ .width = 60, .height = 60 } } })({});
                    clay.text(profile_text, comptime &.{ .font_size = 24, .text_color = .black, .text_alignment = .right });
                });
            });

            clay.ui()(.{ .id = .id("RightPanel"), .layout = .{ .layout_direction = .top_to_bottom, .sizing = .{ .width = .grow(.{}), .height = .grow(.{}) }, .child_gap = 16 } })({
                clay.ui()(.{ .layout = .{ .sizing = .{ .width = .grow(.{}) }, .child_alignment = .top_right, .padding = .all(8), .child_gap = 8 }, .background_color = .rgb(180, 180, 180) })({
                    renderHeaderButton("Header Item 1");
                    renderHeaderButton("Header Item 2");
                    renderHeaderButton("Header Item 3");
                });
                clay.ui()(.{
                    .id = .id("MainContent"),
                    .layout = .{ .layout_direction = .top_to_bottom, .padding = .all(16), .child_gap = 16, .sizing = .{ .width = .grow(.{}) } },
                    .background_color = .rgb(200, 200, 255),
                    .scroll = .{ .vertical = true },
                })({
                    clay.ui()(.{
                        .id = .id("FloatingContainer"),
                        .layout = .{ .sizing = .{ .width = .fixed(300), .height = .fixed(300) }, .padding = .all(16) },
                        .background_color = .rgba(140, 80, 200, 200),
                        .floating = .{ .attach_to = .parent, .z_index = 1, .attach_points = .{ .element = .center_top, .parent = .center_top }, .offset = .{ .x = 0, .y = 0 } },
                        .border = .{ .width = .outside(2), .color = .rgb(80, 80, 80) },
                    })({
                        clay.text("I'm an inline floating container.", comptime &.{ .font_size = 24, .text_color = .rgb(255, 255, 255) });
                    });

                    clay.text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt.", comptime &.{ .font_id = font_id_body_24, .font_size = 24, .text_color = .black });

                    clay.ui()(.{ .id = .id("Photos2"), .layout = .{ .child_gap = 16, .padding = .all(16) }, .background_color = .rgb(180, 180, 220) })({
                        clay.ui()(.{ .id = .id("Picture4"), .layout = .{ .sizing = .{ .width = .fixed(120), .height = .fixed(120) } }, .image = .{ .image_data = &profile_picture, .source_dimensions = .{ .width = 120, .height = 120 } } })({});
                        clay.ui()(.{ .id = .id("Picture5"), .layout = .{ .sizing = .{ .width = .fixed(120), .height = .fixed(120) } }, .image = .{ .image_data = &profile_picture, .source_dimensions = .{ .width = 120, .height = 120 } } })({});
                        clay.ui()(.{ .id = .id("Picture6"), .layout = .{ .sizing = .{ .width = .fixed(120), .height = .fixed(120) } }, .image = .{ .image_data = &profile_picture, .source_dimensions = .{ .width = 120, .height = 120 } } })({});
                    });

                    clay.text("Faucibus purus in massa tempor nec. Nec ullamcorper sit amet risus nullam eget felis eget nunc. Diam vulputate ut pharetra sit amet aliquam id diam. Lacus suspendisse faucibus interdum posuere lorem. A diam sollicitudin tempor id. Amet massa vitae tortor condimentum lacinia. Aliquet nibh praesent tristique magna.", comptime &.{ .font_size = 24, .line_height = 60, .text_color = .black, .text_alignment = .center });

                    clay.text("Suspendisse in est ante in nibh. Amet venenatis urna cursus eget nunc scelerisque viverra. Elementum sagittis vitae et leo duis ut diam quam nulla. Enim nulla aliquet porttitor lacus. Pellentesque habitant morbi tristique senectus et. Facilisi nullam vehicula ipsum a arcu cursus vitae.\nSem fringilla ut morbi tincidunt. Euismod quis viverra nibh cras pulvinar mattis nunc sed. Velit sed ullamcorper morbi tincidunt ornare massa. Varius quam quisque id diam vel quam. Nulla pellentesque dignissim enim sit amet venenatis. Enim lobortis scelerisque fermentum dui faucibus in. Pretium viverra suspendisse potenti nullam ac tortor vitae. Lectus vestibulum mattis ullamcorper velit sed. Eget mauris pharetra et ultrices neque ornare aenean euismod elementum. Habitant morbi tristique senectus et. Integer vitae justo eget magna fermentum iaculis eu. Semper quis lectus nulla at volutpat diam. Enim praesent elementum facilisis leo. Massa vitae tortor condimentum lacinia quis vel.", comptime &.{ .font_size = 24, .text_color = .black });

                    clay.ui()(.{ .id = .id("Photos"), .layout = .{ .sizing = .{ .width = .grow(.{}) }, .child_alignment = .center, .child_gap = 16, .padding = .all(16) }, .background_color = .rgb(180, 180, 220) })({
                        clay.ui()(.{ .id = .id("Picture2"), .layout = .{ .sizing = .{ .width = .fixed(120), .height = .fixed(120) } }, .image = .{ .image_data = &profile_picture, .source_dimensions = .{ .width = 120, .height = 120 } } })({});
                        clay.ui()(.{ .id = .id("Picture1"), .layout = .{ .child_alignment = .top_center, .layout_direction = .top_to_bottom, .padding = .all(8) }, .background_color = .rgb(170, 170, 220) })({
                            clay.ui()(.{ .id = .id("ProfilePicture2"), .layout = .{ .sizing = .{ .width = .fixed(60), .height = .fixed(60) } }, .image = .{ .image_data = &profile_picture, .source_dimensions = .{ .width = 60, .height = 60 } } })({});
                            clay.text("Image caption below", comptime &.{ .font_size = 24, .text_color = .black });
                        });
                        clay.ui()(.{ .id = .id("Picture3"), .layout = .{ .sizing = .{ .width = .fixed(120), .height = .fixed(120) } }, .image = .{ .image_data = &profile_picture, .source_dimensions = .{ .width = 120, .height = 120 } } })({});
                    });

                    clay.text("Amet cursus sit amet dictum sit amet justo donec. Et malesuada fames ac turpis egestas maecenas. A lacus vestibulum sed arcu non odio euismod lacinia. Gravida neque convallis a cras. Dui nunc mattis enim ut tellus elementum sagittis vitae et. Orci sagittis eu volutpat odio facilisis mauris. Neque gravida in fermentum et sollicitudin ac orci. Ultrices dui sapien eget mi proin sed libero. Euismod quis viverra nibh cras pulvinar mattis. Diam volutpat commodo sed egestas egestas. In fermentum posuere urna nec tincidunt praesent semper. Integer eget aliquet nibh praesent tristique magna.\nId cursus metus aliquam eleifend mi in. Sed pulvinar proin gravida hendrerit lectus a. Etiam tempor orci eu lobortis elementum nibh tellus. Nullam vehicula ipsum a arcu cursus vitae. Elit scelerisque mauris pellentesque pulvinar pellentesque habitant morbi tristique senectus. Condimentum lacinia quis vel eros donec ac odio. Mattis pellentesque id nibh tortor id aliquet lectus. Turpis egestas integer eget aliquet nibh praesent tristique. Porttitor massa id neque aliquam vestibulum morbi. Mauris commodo quis imperdiet massa tincidunt nunc pulvinar sapien et. Nunc scelerisque viverra mauris in aliquam sem fringilla. Suspendisse ultrices gravida dictum fusce ut placerat orci nulla.\nLacus laoreet non curabitur gravida arcu ac tortor dignissim. Urna nec tincidunt praesent semper feugiat nibh sed pulvinar. Tristique senectus et netus et malesuada fames ac. Nunc aliquet bibendum enim facilisis gravida. Egestas maecenas pharetra convallis posuere morbi leo urna molestie. Sapien nec sagittis aliquam malesuada bibendum arcu vitae elementum curabitur. Ac turpis egestas maecenas pharetra convallis posuere morbi leo urna. Viverra vitae congue eu consequat. Aliquet enim tortor at auctor urna. Ornare massa eget egestas purus viverra accumsan in nisl nisi. Elit pellentesque habitant morbi tristique senectus et netus et malesuada.\nSuspendisse ultrices gravida dictum fusce ut placerat orci nulla pellentesque. Lobortis feugiat vivamus at augue eget arcu. Vitae justo eget magna fermentum iaculis eu. Gravida rutrum quisque non tellus orci. Ipsum faucibus vitae aliquet nec. Nullam non nisi est sit amet. Nunc consequat interdum varius sit amet mattis vulputate enim. Sem fringilla ut morbi tincidunt augue interdum. Vitae purus faucibus ornare suspendisse. Massa tincidunt nunc pulvinar sapien et. Fringilla ut morbi tincidunt augue interdum velit euismod in. Donec massa sapien faucibus et. Est placerat in egestas erat imperdiet. Gravida rutrum quisque non tellus. Morbi non arcu risus quis varius quam quisque id diam. Habitant morbi tristique senectus et netus et malesuada fames ac. Eget lorem dolor sed viverra.\nOrnare massa eget egestas purus viverra. Varius vel pharetra vel turpis nunc eget lorem. Consectetur purus ut faucibus pulvinar elementum. Placerat in egestas erat imperdiet sed euismod nisi. Interdum velit euismod in pellentesque massa placerat duis ultricies lacus. Aliquam nulla facilisi cras fermentum odio eu. Est pellentesque elit ullamcorper dignissim cras tincidunt. Nunc sed id semper risus in hendrerit gravida rutrum. A pellentesque sit amet porttitor eget dolor morbi. Pellentesque habitant morbi tristique senectus et netus et malesuada fames. Nisl nunc mi ipsum faucibus vitae aliquet nec ullamcorper. Sed id semper risus in hendrerit gravida. Tincidunt praesent semper feugiat nibh. Aliquet lectus proin nibh nisl condimentum id venenatis a. Enim sit amet venenatis urna cursus eget. In egestas erat imperdiet sed euismod nisi porta lorem mollis. Lacinia quis vel eros donec ac odio tempor orci. Donec pretium vulputate sapien nec sagittis aliquam malesuada bibendum arcu. Erat pellentesque adipiscing commodo elit at.\nEgestas sed sed risus pretium quam vulputate. Vitae congue mauris rhoncus aenean vel elit scelerisque mauris pellentesque. Aliquam malesuada bibendum arcu vitae elementum. Congue mauris rhoncus aenean vel elit scelerisque mauris. Pellentesque dignissim enim sit amet venenatis urna cursus. Et malesuada fames ac turpis egestas sed tempus urna. Vel fringilla est ullamcorper eget nulla facilisi etiam dignissim. Nibh cras pulvinar mattis nunc sed blandit libero. Fringilla est ullamcorper eget nulla facilisi etiam dignissim. Aenean euismod elementum nisi quis eleifend quam adipiscing vitae proin. Mauris pharetra et ultrices neque ornare aenean euismod elementum. Ornare quam viverra orci sagittis eu. Odio ut sem nulla pharetra diam sit amet nisl suscipit. Ornare lectus sit amet est. Ullamcorper sit amet risus nullam eget. Tincidunt lobortis feugiat vivamus at augue eget arcu dictum.\nUrna nec tincidunt praesent semper feugiat nibh. Ut venenatis tellus in metus vulputate eu scelerisque felis. Cursus risus at ultrices mi tempus. In pellentesque massa placerat duis ultricies lacus sed turpis. Platea dictumst quisque sagittis purus. Cras adipiscing enim eu turpis egestas. Egestas sed tempus urna et pharetra pharetra. Netus et malesuada fames ac turpis egestas integer eget aliquet. Ac turpis egestas sed tempus. Sed lectus vestibulum mattis ullamcorper velit sed. Ante metus dictum at tempor commodo ullamcorper a. Augue neque gravida in fermentum et sollicitudin ac. Praesent semper feugiat nibh sed pulvinar proin gravida. Metus aliquam eleifend mi in nulla posuere sollicitudin aliquam ultrices. Neque gravida in fermentum et sollicitudin ac orci phasellus egestas.\nRidiculus mus mauris vitae ultricies. Morbi quis commodo odio aenean. Duis ultricies lacus sed turpis. Non pulvinar neque laoreet suspendisse interdum consectetur. Scelerisque eleifend donec pretium vulputate sapien nec sagittis aliquam. Volutpat est velit egestas dui id ornare arcu odio ut. Viverra tellus in hac habitasse platea dictumst vestibulum rhoncus est. Vestibulum lectus mauris ultrices eros. Sed blandit libero volutpat sed cras ornare. Id leo in vitae turpis massa sed elementum tempus. Gravida dictum fusce ut placerat orci nulla pellentesque. Pretium quam vulputate dignissim suspendisse in. Nisl suscipit adipiscing bibendum est ultricies integer quis auctor. Risus viverra adipiscing at in tellus. Turpis nunc eget lorem dolor sed viverra ipsum. Senectus et netus et malesuada fames ac. Habitasse platea dictumst vestibulum rhoncus est. Nunc sed id semper risus in hendrerit gravida. Felis eget velit aliquet sagittis id. Eget felis eget nunc lobortis.\nMaecenas pharetra convallis posuere morbi leo. Maecenas volutpat blandit aliquam etiam. A condimentum vitae sapien pellentesque habitant morbi tristique senectus et. Pulvinar mattis nunc sed blandit libero volutpat sed. Feugiat in ante metus dictum at tempor commodo ullamcorper. Vel pharetra vel turpis nunc eget lorem dolor. Est placerat in egestas erat imperdiet sed euismod. Quisque non tellus orci ac auctor augue mauris augue. Placerat vestibulum lectus mauris ultrices eros in cursus turpis. Enim nunc faucibus a pellentesque sit. Adipiscing vitae proin sagittis nisl. Iaculis at erat pellentesque adipiscing commodo elit at imperdiet. Aliquam sem fringilla ut morbi.\nArcu odio ut sem nulla pharetra diam sit amet nisl. Non diam phasellus vestibulum lorem sed. At erat pellentesque adipiscing commodo elit at. Lacus luctus accumsan tortor posuere ac ut consequat. Et malesuada fames ac turpis egestas integer. Tristique magna sit amet purus. A condimentum vitae sapien pellentesque habitant. Quis varius quam quisque id diam vel quam. Est ullamcorper eget nulla facilisi etiam dignissim diam quis. Augue interdum velit euismod in pellentesque massa. Elit scelerisque mauris pellentesque pulvinar pellentesque habitant. Vulputate eu scelerisque felis imperdiet. Nibh tellus molestie nunc non blandit massa. Velit euismod in pellentesque massa placerat. Sed cras ornare arcu dui. Ut sem viverra aliquet eget sit. Eu lobortis elementum nibh tellus molestie nunc non. Blandit libero volutpat sed cras ornare arcu dui vivamus.\nSit amet aliquam id diam maecenas. Amet risus nullam eget felis eget nunc lobortis mattis aliquam. Magna sit amet purus gravida. Egestas purus viverra accumsan in nisl nisi. Leo duis ut diam quam. Ante metus dictum at tempor commodo ullamcorper. Ac turpis egestas integer eget. Fames ac turpis egestas integer eget aliquet nibh. Sem integer vitae justo eget magna fermentum. Semper auctor neque vitae tempus quam pellentesque nec nam aliquam. Vestibulum mattis ullamcorper velit sed. Consectetur adipiscing elit duis tristique sollicitudin nibh. Massa id neque aliquam vestibulum morbi blandit cursus risus.\nCursus sit amet dictum sit amet justo donec enim diam. Egestas erat imperdiet sed euismod. Nullam vehicula ipsum a arcu cursus vitae congue mauris. Habitasse platea dictumst vestibulum rhoncus est pellentesque elit. Duis ultricies lacus sed turpis tincidunt id aliquet risus feugiat. Faucibus ornare suspendisse sed nisi lacus sed viverra. Pretium fusce id velit ut tortor pretium viverra. Fermentum odio eu feugiat pretium nibh ipsum consequat nisl vel. Senectus et netus et malesuada. Tellus pellentesque eu tincidunt tortor aliquam. Aenean sed adipiscing diam donec adipiscing tristique risus nec feugiat. Quis vel eros donec ac odio. Id interdum velit laoreet id donec ultrices tincidunt.\nMassa id neque aliquam vestibulum morbi blandit cursus risus at. Enim tortor at auctor urna nunc id cursus metus. Lorem ipsum dolor sit amet consectetur. At quis risus sed vulputate odio. Facilisis mauris sit amet massa vitae tortor condimentum lacinia quis. Et malesuada fames ac turpis egestas maecenas. Bibendum arcu vitae elementum curabitur vitae nunc sed velit dignissim. Viverra orci sagittis eu volutpat odio facilisis mauris. Adipiscing bibendum est ultricies integer quis auctor elit sed. Neque viverra justo nec ultrices dui sapien. Elementum nibh tellus molestie nunc non blandit massa enim. Euismod elementum nisi quis eleifend quam adipiscing vitae proin sagittis. Faucibus ornare suspendisse sed nisi. Quis viverra nibh cras pulvinar mattis nunc sed blandit. Tristique senectus et netus et. Magnis dis parturient montes nascetur ridiculus mus.\nDolor magna eget est lorem ipsum dolor. Nibh sit amet commodo nulla. Donec pretium vulputate sapien nec sagittis aliquam malesuada. Cras adipiscing enim eu turpis egestas pretium. Cras ornare arcu dui vivamus arcu felis bibendum ut tristique. Mus mauris vitae ultricies leo integer. In nulla posuere sollicitudin aliquam ultrices sagittis orci. Quis hendrerit dolor magna eget. Nisl tincidunt eget nullam non. Vitae congue eu consequat ac felis donec et odio. Vivamus at augue eget arcu dictum varius duis at. Ornare quam viverra orci sagittis.\nErat nam at lectus urna duis convallis. Massa placerat duis ultricies lacus sed turpis tincidunt id aliquet. Est ullamcorper eget nulla facilisi etiam dignissim diam. Arcu vitae elementum curabitur vitae nunc sed velit dignissim sodales. Tortor vitae purus faucibus ornare suspendisse sed nisi lacus. Neque viverra justo nec ultrices dui sapien eget mi proin. Viverra accumsan in nisl nisi scelerisque eu ultrices. Consequat interdum varius sit amet mattis. In aliquam sem fringilla ut morbi. Eget arcu dictum varius duis at. Nulla aliquet porttitor lacus luctus accumsan tortor posuere. Arcu bibendum at varius vel pharetra vel turpis. Hac habitasse platea dictumst quisque sagittis purus sit amet. Sapien eget mi proin sed libero enim sed. Quam elementum pulvinar etiam non quam lacus suspendisse faucibus interdum. Semper viverra nam libero justo. Fusce ut placerat orci nulla pellentesque dignissim enim sit amet. Et malesuada fames ac turpis egestas maecenas pharetra convallis posuere.\nTurpis egestas sed tempus urna et pharetra pharetra massa. Gravida in fermentum et sollicitudin ac orci phasellus. Ornare suspendisse sed nisi lacus sed viverra tellus in. Fames ac turpis egestas maecenas pharetra convallis posuere. Mi proin sed libero enim sed faucibus turpis. Sit amet mauris commodo quis imperdiet massa tincidunt nunc. Ut etiam sit amet nisl purus in mollis nunc. Habitasse platea dictumst quisque sagittis purus sit amet volutpat consequat. Eget aliquet nibh praesent tristique magna. Sit amet est placerat in egestas erat. Commodo sed egestas egestas fringilla. Enim nulla aliquet porttitor lacus luctus accumsan tortor posuere ac. Et molestie ac feugiat sed lectus vestibulum mattis ullamcorper. Dignissim convallis aenean et tortor at risus viverra. Morbi blandit cursus risus at ultrices mi. Ac turpis egestas integer eget aliquet nibh praesent tristique magna.\nVolutpat sed cras ornare arcu dui. Egestas erat imperdiet sed euismod nisi porta lorem mollis aliquam. Viverra justo nec ultrices dui sapien. Amet risus nullam eget felis eget nunc lobortis. Metus aliquam eleifend mi in. Ut eu sem integer vitae. Auctor elit sed vulputate mi sit amet. Nisl nisi scelerisque eu ultrices. Dictum fusce ut placerat orci nulla. Pellentesque habitant morbi tristique senectus et. Auctor elit sed vulputate mi sit. Tincidunt arcu non sodales neque. Mi in nulla posuere sollicitudin aliquam. Morbi non arcu risus quis varius quam quisque id diam. Cras adipiscing enim eu turpis egestas pretium aenean pharetra magna. At auctor urna nunc id cursus metus aliquam. Mauris a diam maecenas sed enim ut sem viverra. Nunc scelerisque viverra mauris in. In iaculis nunc sed augue lacus viverra vitae congue eu. Volutpat blandit aliquam etiam erat velit scelerisque in dictum non.", comptime &.{ .font_size = 24, .text_color = .black });
                });
            });

            clay.ui()(.{ .id = .id("Blob4Floating2"), .floating = .{ .attach_to = .element_with_id, .z_index = 1, .parent_id = clay.id("SidebarBlob4").id } })({
                clay.ui()(.{ .id = .id("ScrollContainer"), .layout = .{ .sizing = .{ .height = .fixed(200) }, .child_gap = 2 }, .scroll = .{ .vertical = true } })({
                    clay.ui()(.{ .id = .id("FloatingContainer2"), .floating = .{ .attach_to = .parent, .z_index = 1 } })({
                        clay.ui()(.{ .id = .id("FloatingContainerInner"), .layout = .{ .sizing = .{ .width = .fixed(300), .height = .fixed(300) }, .padding = .all(16) }, .background_color = .rgba(140, 80, 200, 200) })({
                            clay.text("I'm an inline floating container.", comptime &.{ .font_size = 24, .text_color = .white });
                        });
                    });
                    clay.ui()(.{ .id = .id("ScrollContainerInner"), .layout = .{ .layout_direction = .top_to_bottom }, .background_color = .rgb(160, 160, 160) })({
                        for (0..100) |i| {
                            renderDropdownTextItem(i);
                        }
                    });
                });
            });
            if (clay.getScrollContainerData(.id("MainContent"))) |scroll_data| {
                clay.ui()(.{ .id = .id("ScrollBar"), .floating = .{ .attach_to = .element_with_id, .offset = .{ .y = -(scroll_data.scroll_position.y / scroll_data.content_dimensions.height) * scroll_data.scroll_container_dimensions.height }, .z_index = 1, .parent_id = clay.id("MainContent").id, .attach_points = .{ .element = .right_top, .parent = .right_top } } })({
                    clay.ui()(.{ .id = .id("ScrollBarButton"), .layout = .{ .sizing = .{ .width = .fixed(12), .height = .fixed((scroll_data.scroll_container_dimensions.height / scroll_data.content_dimensions.height) * scroll_data.scroll_container_dimensions.height) } }, .background_color = if (clay.isPointerOver(.id("ScrollBar"))) .rgba(100, 100, 140, 150) else .rgba(120, 120, 160, 150), .corner_radius = .all(6) })({});
                });
            }
        });
    });
}

const ScrollbarData = struct {
    click_origin: clay.Vector2 = .{},
    position_origin: clay.Vector2 = .{},
    mouse_down: bool = false,
};

var scrollbar_data: ScrollbarData = undefined;

var debug_enabled = false;

fn updateDrawFrame(fonts: [*]rl.Font) void {
    const mouse_wheel_delta = rl.getMouseWheelMoveV();
    const mouse_wheel_x = mouse_wheel_delta.x;
    const mouse_wheel_y = mouse_wheel_delta.y;

    if (rl.isKeyPressed(.d)) {
        debug_enabled = !debug_enabled;
        clay.setDebugModeEnabled(debug_enabled);
    }

    //----------------------------------------------------------------------------------
    // Handle scroll containers
    const mouse_position = raylibToClayVector2(rl.getMousePosition());
    clay.setPointerState(mouse_position, rl.isMouseButtonDown(.left) and !scrollbar_data.mouse_down);
    clay.setLayoutDimensions(screenDimensions());
    if (!rl.isMouseButtonDown(.left)) {
        scrollbar_data.mouse_down = false;
    }

    if (rl.isMouseButtonDown(.left) and !scrollbar_data.mouse_down and clay.isPointerOver(.id("ScrollBar"))) {
        if (clay.getScrollContainerData(.id("MainContent"))) |scroll_container_data| {
            scrollbar_data.click_origin = mouse_position;
            scrollbar_data.position_origin = scroll_container_data.scroll_position.*;
            scrollbar_data.mouse_down = true;
        }
    } else if (scrollbar_data.mouse_down) {
        if (clay.getScrollContainerData(.id("MainContent"))) |scroll_container_data| {
            if (scroll_container_data.content_dimensions.height > 0) {
                const ratio_x = scroll_container_data.content_dimensions.width / scroll_container_data.scroll_container_dimensions.width;
                const ratio_y = scroll_container_data.content_dimensions.height / scroll_container_data.scroll_container_dimensions.height;
                if (scroll_container_data.config.vertical) {
                    scroll_container_data.scroll_position.y = scrollbar_data.position_origin.y + (scrollbar_data.click_origin.y - mouse_position.y) * ratio_y;
                }
                if (scroll_container_data.config.horizontal) {
                    scroll_container_data.scroll_position.x = scrollbar_data.position_origin.x + (scrollbar_data.click_origin.x - mouse_position.x) * ratio_x;
                }
            }
        }
    }

    clay.updateScrollContainers(true, .{ .x = mouse_wheel_x, .y = mouse_wheel_y }, rl.getFrameTime());

    // Generate the auto layout for rendering
    const render_commands = blk: {
        const current_time = rl.getTime();
        defer std.log.debug("layout time: {} microseconds", .{(rl.getTime() - current_time) * 1000 * 1000});

        break :blk createLayout();
    };

    // RENDERING ---------------------------------
    {
        const current_time = rl.getTime();
        defer std.log.debug("render time: {} microseconds", .{(rl.getTime() - current_time) * 1000 * 1000});

        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);
        renderer.render(render_commands, fonts);
        rl.endDrawing();
    }

    //----------------------------------------------------------------------------------

}

var reinitialize_clay = false;

fn handleClayErrors(error_data: clay.ErrorData) callconv(.C) void {
    std.log.err("{s}", .{error_data.error_text.asSlice()});
    switch (error_data.error_type) {
        .elements_capacity_exceeded => {
            reinitialize_clay = true;
            clay.setMaxElementCount(clay.getMaxElementCount() * 2);
        },
        .text_measurement_capacity_exceeded => {
            reinitialize_clay = true;
            clay.setMaxMeasureTextCacheWordCount(clay.getMaxMeasureTextCacheWordCount() * 2);
        },
        else => {},
    }
}

const error_handler: clay.ErrorHandler = .{ .handler = handleClayErrors };

inline fn screenDimensions() clay.Dimensions {
    return .{
        .width = @floatFromInt(rl.getScreenWidth()),
        .height = @floatFromInt(rl.getScreenHeight()),
    };
}

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    var ctx = try clay.Context.init(allocator, screenDimensions(), error_handler);
    defer ctx.deinit(allocator);

    clay.renderers.raylib.initialize(1024, 768, "Clay - Raylib Renderer Example", @bitCast(rl.ConfigFlags{ .vsync_hint = true, .window_resizable = true, .window_highdpi = true, .msaa_4x_hint = true }));

    profile_picture = try rl.loadTextureFromImage(try rl.loadImageFromMemory(".png", @embedFile("resources/profile-picture.png")));

    var fonts: [2]rl.Font = undefined;
    fonts[font_id_body_24] = try rl.loadFontFromMemory(".ttf", @embedFile("resources/Roboto-Regular.ttf"), 24, null);
    rl.setTextureFilter(fonts[font_id_body_24].texture, .bilinear);
    fonts[font_id_body_16] = try rl.loadFontFromMemory(".ttf", @embedFile("resources/Roboto-Regular.ttf"), 16, null);
    rl.setTextureFilter(fonts[font_id_body_16].texture, .bilinear);
    clay.setMeasureTextFunction(clay.renderers.raylib.measureText, &fonts[0]);

    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) // Detect window close button or ESC key
    {
        if (reinitialize_clay) {
            ctx.deinit(allocator);
            ctx = try clay.Context.init(allocator, screenDimensions(), error_handler);
            reinitialize_clay = false;
        }

        updateDrawFrame(&fonts);
    }
}
