# frozen_string_literal: true

module BusinessLogic
  # Raised by an abstract method a subclass must override, or a seam that is
  # deliberately not implemented yet.
  #
  # Use this instead of Ruby's `NotImplementedError`, which — despite the name —
  # is a `ScriptError`, not a `StandardError`: a bare `rescue` never catches it,
  # and Ruby reserves it for features the current platform does not implement (a
  # missing `fork(2)`, for example). `AbstractMethodError` subclasses
  # `NoMethodError` (itself a `StandardError`), so an ordinary `rescue` catches
  # it and it reads as what it is — a method with no implementation here. The
  # `Propitech/NoNotImplementedError` cop enforces the swap.
  class AbstractMethodError < NoMethodError
  end
end
