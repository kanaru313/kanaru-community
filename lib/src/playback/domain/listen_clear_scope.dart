/// A range of `played_at` (epoch ms) a clear removes: `[from, to)`. A `null`
/// side is open, so `(from: null, to: null)` is the whole history.
typedef ClearBounds = ({int? from, int? to});

/// Whether a play that started at [playedAt] lies inside [bounds].
bool boundsCover(ClearBounds bounds, int playedAt) =>
    (bounds.from == null || playedAt >= bounds.from!) &&
    (bounds.to == null || playedAt < bounds.to!);

/// Whether a clear of [bounds] affects a listen that started at [playedAt].
/// One that never played (`null`) is affected: nothing says it lies outside,
/// and dropping it is the safe side.
bool clearTouches(ClearBounds bounds, int? playedAt) =>
    playedAt == null || boundsCover(bounds, playedAt);
