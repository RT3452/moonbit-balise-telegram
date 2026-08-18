///|
/// A lightweight track model for deterministic BTM/ATO integration tests.
pub struct TrackSegment {
  start_distance : Int
  length : Int
  gradient : Int
  static_limit : Int
}

///|
pub fn track_segment(
  start_distance : Int,
  length : Int,
  gradient : Int,
  static_limit : Int,
) -> TrackSegment {
  { start_distance, length, gradient, static_limit }
}

///|
pub struct TrackModel {
  segments : Array[TrackSegment]
}

///|
pub fn track_model(segments : Array[TrackSegment]) -> TrackModel {
  { segments, }
}

///|
pub fn demo_track() -> TrackModel {
  track_model([
    track_segment(0, 250, 2, 80),
    track_segment(250, 300, -4, 60),
    track_segment(550, 450, 0, 120),
    track_segment(1000, 200, 6, 40),
  ])
}

///|
pub enum TrackStatus {
  Safe
  NeedsBraking
  Overspeed
  UnknownLimit
}

///|
pub struct TrackSample {
  distance : Int
  gradient : Int
  static_limit : Int
  allowed_speed : Int
  actual_speed : Int
  braking_distance : Int
  mut status : TrackStatus
}

///|
/// Compute the distance needed to reduce speed under constant braking.
pub fn braking_distance(
  actual_speed : Int,
  target_speed : Int,
  braking : Int,
) -> Int {
  if braking <= 0 || actual_speed <= target_speed {
    0
  } else {
    let difference = actual_speed * actual_speed - target_speed * target_speed
    difference / (2 * braking)
  }
}

///|
fn gradient_adjustment(gradient : Int) -> Int {
  if gradient > 0 {
    gradient / 2
  } else if gradient < 0 {
    gradient / 3
  } else {
    0
  }
}

///|
fn allowed_speed(segment : TrackSegment, profile : TrainProfile) -> Int {
  let adjusted = segment.static_limit - gradient_adjustment(segment.gradient)
  if adjusted < 0 {
    0
  } else if adjusted > profile.max_speed {
    profile.max_speed
  } else {
    adjusted
  }
}

///|
/// Evaluate a constant-speed train against a track model.
pub fn evaluate_track(
  model : TrackModel,
  profile : TrainProfile,
  actual_speed : Int,
) -> Array[TrackSample] {
  let samples = []
  for segment in model.segments {
    let limit = allowed_speed(segment, profile)
    let braking = braking_distance(actual_speed, limit, profile.braking)
    let status = if segment.static_limit < 0 {
      TrackStatus::UnknownLimit
    } else if actual_speed > limit {
      if braking > segment.length {
        TrackStatus::NeedsBraking
      } else {
        TrackStatus::Overspeed
      }
    } else {
      TrackStatus::Safe
    }
    samples.push({
      distance: segment.start_distance,
      gradient: segment.gradient,
      static_limit: segment.static_limit,
      allowed_speed: limit,
      actual_speed,
      braking_distance: braking,
      status,
    })
  }
  samples
}

///|
/// Combine Packet 27 sections with a physical track model.
pub fn evaluate_telegram_track(
  telegram : BaliseTelegram,
  model : TrackModel,
  profile : TrainProfile,
  actual_speed : Int,
) -> Array[TrackSample] {
  let samples = evaluate_track(model, profile, actual_speed)
  let profile_samples = assess_speed_profile(telegram, actual_speed)
  if profile_samples.length() > 0 {
    let mut index = 0
    while index < samples.length() && index < profile_samples.length() {
      if profile_samples[index].status is SafetyStatus::Overspeed {
        samples[index].status = TrackStatus::Overspeed
      }
      index = index + 1
    }
  }
  samples
}

///|
/// Count safety states for dashboards and regression tests.
pub fn track_status_counts(
  samples : Array[TrackSample],
) -> (Int, Int, Int, Int) {
  let mut safe = 0
  let mut braking = 0
  let mut overspeed = 0
  let mut unknown = 0
  for sample in samples {
    match sample.status {
      TrackStatus::Safe => safe = safe + 1
      TrackStatus::NeedsBraking => braking = braking + 1
      TrackStatus::Overspeed => overspeed = overspeed + 1
      TrackStatus::UnknownLimit => unknown = unknown + 1
    }
  }
  (safe, braking, overspeed, unknown)
}
