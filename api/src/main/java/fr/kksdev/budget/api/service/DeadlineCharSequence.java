package fr.kksdev.budget.api.service;

/**
 * CharSequence whose {@link #charAt(int)} fails once a deadline has passed, so that a regex
 * with catastrophic backtracking applied to it stops instead of blocking its thread.
 */
final class DeadlineCharSequence implements CharSequence {

    /** Raised when the deadline is exceeded while a pattern reads the sequence. */
    static final class DeadlineExceededException extends RuntimeException {
        DeadlineExceededException() {
            super("Regex evaluation deadline exceeded", null, false, false);
        }
    }

    private final CharSequence delegate;
    private final long deadlineNanos;

    DeadlineCharSequence(CharSequence delegate, long deadlineNanos) {
        this.delegate = delegate;
        this.deadlineNanos = deadlineNanos;
    }

    @Override
    public char charAt(int index) {
        if (System.nanoTime() - deadlineNanos > 0) {
            throw new DeadlineExceededException();
        }
        return delegate.charAt(index);
    }

    @Override
    public int length() {
        return delegate.length();
    }

    @Override
    public CharSequence subSequence(int start, int end) {
        return new DeadlineCharSequence(delegate.subSequence(start, end), deadlineNanos);
    }

    @Override
    public String toString() {
        return delegate.toString();
    }
}
