package time

// TimeError is every way an operation in this package fails.
public enum TimeError: Error {
    /// The text is not a duration `Duration.Parse` reads, or one too long
    /// to hold.
    case invalidDuration(string)

    /// A sentence naming what failed.
    public var Message: string {
        switch self {
        case .invalidDuration(let text): return "invalid duration: \"\(text)\""
        }
    }
}
