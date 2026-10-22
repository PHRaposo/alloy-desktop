(in-package #:org.shirakumo.alloy.observables)

(docs:define-docs
  (type activity
    "Representation of an observable activity.

An activity is the definition of an endpoint on an observable object
that can be observed by an observer function. Often this corresponds
to a field that changes value, but it can also correspond to other
events that may take place.

Every activity has a defined argument list that will be passed on to
the observer function. If the observer function argument list does not
accept the arguments passed to it, the observation will signal an
error at runtime.

See CL:DOCUMENTATION
See LIST-ACTIVITIES
See FIND-ACTIVITY
See REGISTER-ACTIVITY
See DEFINE-ACTIVITY")

  (type observable
    "Representation of an object that can be observed.

An observable keeps a list of observers for each activity that it
presents. An observer in this context is a function that will be
invoked with a defined set of arguments when the activity is
notified.

Every observer can also define an optional \"specialization\" which is
a type test on the arguments. If the specialization test fails, the
observer function will not be invoked.

Note that even if an activity is not registered officially (and thus
not listed in LIST-ACTIVITIES), observers may still define an
observation on arbitrary activity names. Activities therefore are more
meant as an official documentation of an observable event than a
defined interface.

See LIST-ACTIVITIES
See FIND-ACTIVITY
See REGISTER-ACTIVITY
See OBSERVE
See LIST-OBSERVERS
See NOTIFY-OBSERVERS
See REMOVE-OBSERVERS
See REMOVE-OBSERVER
See ON
See DEFINE-OBSERVATION
See DEFINE-OBSERVABLE")
  
  (function list-activities
    "Return a list of ACTIVITY objects registered with the observable.

See OBSERVABLE (type)
See ACTIVITY (type)")
  
  (function find-activity
    "Find an activity of the given name.

If ERRORP is true, an error is signalled if no activity of the
requested name can be found on the observable.

See OBSERVABLE (type)
See ACTIVITY (type)")
  
  (function register-activity
    "Register a new activity on the given observable.

NAME          --- The name of the activity. The name is unique on the
                  observable, and registering twice will update the
                  existing activity.
ARGS          --- The list of arguments passed to the observer when the
                  activity is notified.
DOCUMENTATION --- An optional documentation string to give user-facing
                  information on what the activity is for and under
                  which circumstances it is notified.

See OBSERVABLE (type)
See ACTIVITY (type)")
  
  (function observe
    "Register an observer on an activity.

ACTIVITY          --- The name of the activity to observe.
OBSERVABLE        --- The object to observe.
OBSERVER-FUNCTION --- The function that will be invoked when the
                      activity is notified.
NAME              --- The name of the observer. Has to be unique.
SPECIALIZE        --- An optional list of type tests for each argument
                      of the activity. If not given, no specialisation
                      test is used and the function will be invoked on
                      every activity notification.

See ON
See DEFINE-OBSERVATION
See OBSERVABLE (type)
See ACTIVITY (type)")
  
  (function remove-observers
    "Remove observers from an activity.

If ACTIVITY is T, all observers from all activities are removed.
Otherwise all observers on the given activity are removed.

See REMOVE-OBSERVER
See OBSERVABLE (type)")

  (function remove-observer
    "Remove a specific observer by name.

If the observer does not exist, nothing is done.

See REMOVE-OBSERVERS
See OBSERVABLE (type)")
  
  (function list-observers
    "List the names of all observers on the given activity.

See OBSERVABLE (type)")
  
  (function notify-observers
    "Notify the observers of the given activity.

ACTIVITY   --- The name of the activity to notify, or \"trigger\".
OBSERVABLE --- The observable object that observers of the activity
               need to be registered with.
ARGS       --- The arguments to pass along with the activity. Note
               that those must match the arglist defined on the
               activity, otherwise this will fail and signal an error.

Does not return anything useful.

See OBSERVABLE (type)
See ACTIVITY (type)")
  
  (function make-observable
    "Turn the given thing into something observable.

THING is most often a function or name for a function. In that case,
the function will be instrumented to notify an activity using one of
the arguments to the function as the OBSERVABLE object. The name of
the activity must be passed as a keyword argument. Additionally, you
may pass :CLASS that will specify the class of observable on which the
activity is registered, and on which the function will specialise.
:INVOKE may be used with either :AFTER or :BEFORE to specify whether
the activity should be notified after or before the primary function
being instrumented runs.

If THING is a symbol naming a function, then that same name is used as
the default :ACTIVITY argument.

LAMBDA-LIST must be the lambda-list of the function, and one of the
required arguments in the list must be named OBSERVABLE, to identify
the observable object on which to notify the activity. All other
arguments of the lambda-list are passed on to the activity
notification as arguments.

Note that you can usually \"manually\" achieve the same effect as this
function by using REGISTER-ACTIVITY and NOTIFY-OBSERVERS as
appropriate.

See REGISTER-ACTIVITY
See NOTIFY-OBSERVERS
See OBSERVABLE (type)
See ACTIVITY (type)")
  
  (function define-activity
    "Shorthand to define an activity on a class.

This is a convenience macro for invoking REGISTER-ACTIVITY on the
class named as the OBSERVABLE. BODY can be a plist of extra arguments
to pass on, optionally starting with a string that provides the
:DOCUMENTATION argument.

See REGISTER-ACTIVITY")
  
  (function define-activities
    "Shorthand to define multiple activities on a class.

This is another convenience macro, simply filling in the same
OBSERVABLE on all body clauses. Each body clause should hold the
activity name, the argument list, and the other options to pass along
as the body.

See DEFINE-ACTIVITY")
  
  (function on
    "Shorthand to conveniently OBSERVE an activity dynamically.

ACTIVITY   --- The name of the activity to observe.
OBSERVABLE --- The observable object to place the observation on.
ARGS       --- The arguments list to bind the activity arguments with.
               The list may be NIL to ignore all arguments, or
               each argument can be one of the following:
  (EQL value) --- Ignoring the argument and specializing it to be
                  equal to the (evaluated) VALUE.
  (name type) --- Bind the argument value to NAME and specialize it to
                  match the (unevaluated) TYPE.
  name        --- Bind the argument value to NAME. This is equivalent
                  to (name T).
BODY       --- The body forms to execute when the activity is
               notified. Additionally a special declaration is
               available: (declare (name ..)) to define the name of
               the observer.

See OBSERVE")
  
  (function define-observation
    "Shorthand to define a global observation function.

This will define a function of NAME, ARGS, and BODY. BODY may contain
special declarations of this form:

  (DECLARE (OBSERVE activity class...))

Where ACTIVITY is the name of the activity to observe on every
instance of CLASS. Essentially for every such declaration an OBSERVE
form will be emitted as well.

ACTIVITY can either be the name of an activity, or a list composed of
the name of the activity and the argument specializers to use:

  (DECLARE (OBSERVE (activity specialization...) class...))

Unlike ON, this will also check your argument list on every activity
you observe for whether they match, and whether the activity is even
registered. If either do not, a warning is signalled.

See FIND-ACTIVITY
See OBSERVE")
  
  (function define-observable
    "Shorthand to define an observable generic function.

This is a shorthand for DEFGENERIC combined with MAKE-OBSERVABLE.
Aside from the standard DEFGENERIC options, you can also provide
:ACTIVITY, :CLASS, and :INVOKE which will be provided to
MAKE-OBSERVABLE instead. The :DOCUMENTATION option will also be
forwarded to the activity.

Note in the case of a SETF function like (SETF foo) the activity will
be named foo, rather than (setf foo).

See MAKE-OBSERVABLE
See DEFINE-ACTIVITY")
  
  (type observable-object
    "Superclass for objects that should have observable slots.

For every slot that is set, the SLOT-VALUE activity is invoked with
the value, the object, and the slot name, same as the argument order
on (setf slot-value).

See OBSERVABLE (type)"))
