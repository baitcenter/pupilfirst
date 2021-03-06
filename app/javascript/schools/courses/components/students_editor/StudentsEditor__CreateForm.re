[@bs.config {jsx: 3}];

open StudentsEditor__Types;

type state = {
  studentsToAdd: array(StudentInfo.t),
  saving: bool,
};

type action =
  | AddStudentInfo(StudentInfo.t)
  | RemoveStudentInfo(StudentInfo.t)
  | SetSaving(bool);

let str = React.string;

let formInvalid = state => state.studentsToAdd |> ArrayUtils.isEmpty;
let handleErrorCB = (send, ()) => send(SetSaving(false));

/* Get the tags applied to a list of students. */
let appliedTags = students =>
  students
  |> Array.map(student => student |> StudentInfo.tags |> Array.to_list)
  |> Array.to_list
  |> List.flatten
  |> ListUtils.distinct
  |> Array.of_list;

/*
 * This is a union of tags reported by the parent component, and tags currently applied to students listed in the form. This allows the
 * form to suggest tags that haven't yet been persisted, but have been applied to at least one of the students in the list.
 */
let allKnownTags = (incomingTags, appliedTags) =>
  incomingTags |> Array.append(appliedTags) |> ArrayUtils.distinct;

let handleResponseCB = (submitCB, state, json) => {
  let (studentsAdded, studentsRequested) =
    json |> Json.Decode.(field("studentCount", pair(int, int)));
  let tags = state.studentsToAdd |> appliedTags;

  submitCB(tags);

  if (studentsAdded == studentsRequested) {
    Notification.success(
      "Success",
      "All students were created successfully.",
    );
  } else {
    let message =
      (studentsAdded |> string_of_int)
      ++ " of "
      ++ (studentsRequested |> string_of_int)
      ++ " students were added. Remaining students are already a part of the course.";
    Notification.notice("Partially successful", message);
  };
};

let saveStudents = (state, send, courseId, responseCB, event) => {
  event |> ReactEvent.Mouse.preventDefault;
  send(SetSaving(true));
  let payload = Js.Dict.empty();
  Js.Dict.set(
    payload,
    "authenticity_token",
    AuthenticityToken.fromHead() |> Js.Json.string,
  );
  Js.Dict.set(
    payload,
    "students",
    state.studentsToAdd |> Json.Encode.(array(StudentInfo.encode)),
  );

  let url = "/school/courses/" ++ courseId ++ "/students";
  Api.create(url, payload, responseCB, handleErrorCB(send));
};

let renderTitleAndAffiliation = (title, affiliation) => {
  let text =
    switch (title == "", affiliation == "") {
    | (true, true) => None
    | (true, false) => Some(affiliation)
    | (false, true) => Some(title)
    | (false, false) => Some(title ++ ", " ++ affiliation)
    };

  switch (text) {
  | Some(text) =>
    <div className="flex items-center">
      <div className="mr-1 text-xs text-gray-600"> {text |> str} </div>
    </div>
  | None => React.null
  };
};

let initialState = () => {studentsToAdd: [||], saving: false};

let reducer = (state, action) =>
  switch (action) {
  | AddStudentInfo(studentInfo) => {
      ...state,
      studentsToAdd: state.studentsToAdd |> Array.append([|studentInfo|]),
    }
  | RemoveStudentInfo(studentInfo) => {
      ...state,
      studentsToAdd:
        state.studentsToAdd
        |> Js.Array.filter(s =>
             StudentInfo.email(s) !== StudentInfo.email(studentInfo)
           ),
    }
  | SetSaving(saving) => {...state, saving}
  };

[@react.component]
let make = (~courseId, ~submitFormCB, ~studentTags) => {
  let (state, send) = React.useReducer(reducer, initialState());
  <div className="mx-auto bg-white">
    <div className="max-w-2xl p-6 mx-auto">
      <h5 className="uppercase text-center border-b border-gray-400 pb-2 mb-4">
        {"Student Details" |> str}
      </h5>
      <StudentsEditor__StudentInfoForm
        addToListCB={studentInfo => send(AddStudentInfo(studentInfo))}
        studentTags={allKnownTags(
          studentTags,
          state.studentsToAdd |> appliedTags,
        )}
        emailsToAdd={
          state.studentsToAdd
          |> Array.map(student => student |> StudentInfo.email)
        }
      />
      <div>
        <div className="mt-5">
          <div className="inline-block tracking-wide text-xs font-semibold">
            {"These new students will be added to the course:" |> str}
          </div>
          {switch (state.studentsToAdd) {
           | [||] =>
             <div
               className="flex items-center justify-between bg-gray-100 border rounded p-3 italic mt-2">
               {"This list is empty! Add some students using the form above."
                |> str}
             </div>
           | studentInfos =>
             studentInfos
             |> Array.map(studentInfo =>
                  <div
                    key={studentInfo |> StudentInfo.email}
                    className="flex justify-between bg-white-100 border shadow rounded-lg mt-2">
                    <div className="flex flex-col flex-1 flex-wrap p-3">
                      <div className="flex items-center">
                        <div className="mr-1 font-semibold">
                          {studentInfo |> StudentInfo.name |> str}
                        </div>
                        <div className="text-xs text-gray-600">
                          {" ("
                           ++ (studentInfo |> StudentInfo.email)
                           ++ ")"
                           |> str}
                        </div>
                      </div>
                      {renderTitleAndAffiliation(
                         studentInfo |> StudentInfo.title,
                         studentInfo |> StudentInfo.affiliation,
                       )}
                      <div className="flex flex-wrap">
                        {studentInfo
                         |> StudentInfo.tags
                         |> Array.map(tag =>
                              <div
                                key=tag
                                className="flex items-center bg-gray-200 border border-gray-500 rounded-lg px-2 py-px mt-1 mr-1 text-xs text-gray-900 overflow-hidden">
                                {tag |> str}
                              </div>
                            )
                         |> React.array}
                      </div>
                    </div>
                    <button
                      className="p-3 text-gray-700 hover:text-gray-900 hover:bg-gray-100"
                      onClick={_event =>
                        send(RemoveStudentInfo(studentInfo))
                      }>
                      <i className="fas fa-trash-alt" />
                    </button>
                  </div>
                )
             |> React.array
           }}
        </div>
      </div>
      <div className="flex mt-4">
        <button
          disabled={state.saving || state.studentsToAdd |> ArrayUtils.isEmpty}
          onClick={saveStudents(
            state,
            send,
            courseId,
            handleResponseCB(submitFormCB, state),
          )}
          className={
            "w-full btn btn-primary btn-large mt-3"
            ++ (formInvalid(state) ? " disabled" : "")
          }>
          {(state.saving ? "Saving..." : "Save List") |> str}
        </button>
      </div>
    </div>
  </div>;
};
