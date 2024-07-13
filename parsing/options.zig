/// Number of words that are on screen at once
wordcount: u32 = 32,
behaviourBackspace: BehaviourBackspace = .mistake,
behaviourNavigation: BehaviourNavigation = .none,
behaviourTyping: BehaviourTyping = .append,
behaviourLesson: BehaviourLesson = .normal,

/// gracePeriod that is used by Timing Behaviour
gracePeriod: f32 = 0.5,
behaviourTiming: BehaviourTiming = .graceful,

const std = @import("std");

/// Enum for how the Backspace key (<BS>) behaves
pub const BehaviourBackspace = enum {
  /// Backspace does nothing
  never,
  /// Backspace deletes mistakes only right before the cursor
  mistake,
  /// Backspace deletes mistakes, wraps to last mistake
  skipToMistake,
  /// Backspace deletes last word always
  always,
};

/// Enum for how the Navigation keys (<Right>, <Up>, <Left>, <Down>) behave
pub const BehaviourNavigation = enum {
  /// Navigation keys do nothing
  none,
  /// Only go Right and Left, wrap at line endings
  leftRight,
  /// Right Down Left Up all work as expected, you cannot go out of text bounds
  all,
};

/// Enum for changing typing behaviour
pub const BehaviourTyping = enum {
  /// Stop cursor on mistake
  stop,
  /// Skip the word that was typed incorrectly
  skip,
  /// Append the wrong word to current position, move everything forewerd
  append,
};

/// Enum for changing how/if Lessons appear
pub const BehaviourLesson = enum {
  /// Lessons work as expected
  normal,
  /// Words disappear as you type them, next n words are generated continuously
  continuous,
};

/// Enum for controlling how timing works for typing speed calculations
pub const BehaviourTiming = enum {
  /// time keeps accumulating even if you don't press a key for an hour
  punishing,
  /// Stop accumulating time after the `gracePeriod`
  graceful,
};

// const BehaviourForgive = enum {
// };

