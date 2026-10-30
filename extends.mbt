///|
pub extend Entry with Show::{to_string, output}

///|
pub extend Entry with ToJson::{to_json}

///|
pub extend File with Handler::{handle}

///|
pub extend Level with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Level with Eq::{not_equal, equal}

///|
pub extend Level with Show::{to_string, output}

///|
pub extend Multi with Handler::{handle}

///|
pub extend Stdout with Handler::{handle}
