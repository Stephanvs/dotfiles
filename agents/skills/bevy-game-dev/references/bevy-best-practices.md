# Bevy Best Practices Reference

## Entities
- Spawn top-level entities with a `Name` and cleanup component (or `StateScoped`).
- Child entities can rely on parent cleanup.

```rust
commands.spawn((
    Name::new("Player"),
    StateScoped(GameState::InGame),
    // other components
));
```

## Strong IDs
Use your own ID types for persistence or networking instead of `Entity`.

```rust
#[derive(Reflect, Debug, PartialEq, Eq, Clone, Copy)]
pub(crate) struct QuestId(u32);

#[derive(Resource, Debug)]
struct QuestGlobalState { next_quest_id: u32 }

impl QuestGlobalState {
    fn quest_id(&mut self) -> QuestId {
        let id = self.next_quest_id;
        self.next_quest_id += 1;
        QuestId(id)
    }
}
```

## System Scheduling
- Bound `Update` systems with `run_if` and `SystemSet`.
- Co-locate `OnEnter`/`OnExit` registrations for a state.

```rust
app.add_systems(
    Update,
    (handle_player_input, camera_view_update)
        .chain()
        .run_if(in_state(PlayingState::Playing))
        .run_if(in_state(GameState::InGame))
        .in_set(UpdateSet::Player),
);

app.add_systems(OnEnter(GameState::MainMenu), main_menu_setup)
   .add_systems(OnExit(GameState::MainMenu), cleanup_system::<CleanupMenuClose>);
```

## Events
- Use events to decouple gameplay subsystems.
- Ensure writers run before readers in the same frame.
- Add run criteria to event-handling systems.

```rust
handle_player_level_up_event.run_if(on_event::<PlayerLevelUpEvent>());
```

## Helpers
Cleanup systems with a ZST marker:

```rust
#[derive(Component)]
struct CleanupInGamePlayingExit;

fn cleanup_system<T: Component>(mut commands: Commands, q: Query<Entity, With<T>>) {
    q.for_each(|e| commands.entity(e).despawn_recursive());
}
```

Getter macro pattern for early returns:

```rust
#[macro_export]
macro_rules! get_single {
    ($q:expr) => {
        match $q.get_single() { Ok(m) => m, _ => return }
    };
}
```

## Project Structuring
- Use a `prelude` module to centralize common imports.
- Group subsystems into internal plugins (`fn plugin(app: &mut App)`).
- Compose the app from plugins in `main`.

## Performance & Builds
Recommended compile-time logging reduction:

```toml
log = { version = "0.4", features = ["max_level_debug", "release_max_level_warn"] }
```

Dev profile and dynamic linking:

```toml
[features]
dev = ["bevy/dynamic_linking", "bevy/file_watcher", "bevy/asset_processor"]

[profile.dev]
debug = 0
strip = "debuginfo"
opt-level = 0

[profile.dev.package."*"]
opt-level = 2
```

Run:

```sh
cargo run --features dev
```

Release profile:

```toml
[profile.release]
opt-level = 3
panic = "abort"
debug = 0
strip = "debuginfo"
# lto = "thin"
```

Distribution profile:

```toml
[profile.distribution]
inherits = "release"
strip = true
lto = "thin"
codegen-units = 1
```

Distribution build with logging disabled:

```sh
cargo build --profile distribution -F tracing/release_max_level_off -F log/release_max_level_off
```
