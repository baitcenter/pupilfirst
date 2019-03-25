open CourseEditor__Types;

module CoursesQuery = [%graphql
  {|
  query {
    courses{
      id
      name
      endsAt
      maxGrade
      passGrade
      gradesAndLabels {
        grade
        label
      }
    }
  }
|}
];

type props = {authenticityToken: string};

type editorAction =
  | Hidden
  | ShowForm(option(Course.t));

type state = {
  editorAction,
  courses: list(Course.t),
};

type action =
  | UpdateEditorAction(editorAction)
  | UpdateCourse(Course.t)
  | UpdateCourses(list(Course.t));

let str = ReasonReact.string;

let component = ReasonReact.reducerComponent("CourseEditor");

let make = (~authenticityToken, _children) => {
  ...component,
  initialState: () => {editorAction: Hidden, courses: []},
  reducer: (action, state) =>
    switch (action) {
    | UpdateEditorAction(editorAction) =>
      ReasonReact.Update({...state, editorAction})
    | UpdateCourses(courses) => ReasonReact.Update({...state, courses})
    | UpdateCourse(course) =>
      let newCourses = course |> Course.updateList(state.courses);
      ReasonReact.Update({...state, courses: newCourses});
    },
  didMount: ({send}) => {
    let coursesQuery = CoursesQuery.make();
    let response = coursesQuery |> GraphqlQuery.sendQuery(authenticityToken);
    response
    |> Js.Promise.then_(result => {
         let courses =
           result##courses
           |> Js.Array.map(rawCourse => {
                let endsAt =
                  switch (rawCourse##endsAt) {
                  | Some(endsAt) => Some(endsAt |> Json.Decode.string)
                  | None => None
                  };
                let gradesAndLabels =
                  rawCourse##gradesAndLabels
                  |> Array.map(gradesAndLabel =>
                       GradesAndLabels.create(
                         gradesAndLabel##grade,
                         gradesAndLabel##label,
                       )
                     )
                  |> Array.to_list;

                Course.create(
                  rawCourse##id |> int_of_string,
                  rawCourse##name,
                  endsAt,
                  rawCourse##maxGrade,
                  rawCourse##passGrade,
                  gradesAndLabels,
                );
              })
           |> Array.to_list;
         send(UpdateCourses(courses));
         Js.Promise.resolve();
       })
    |> ignore;
  },
  render: ({state, send}) => {
    let hideEditorActionCB = () => send(UpdateEditorAction(Hidden));
    let updateCoursesCB = course => {
      send(UpdateCourse(course));
      send(UpdateEditorAction(Hidden));
    };
    <div className="flex flex-1 h-screen">
      {
        switch (state.editorAction) {
        | Hidden => ReasonReact.null
        | ShowForm(course) =>
          <CourseEditor__Form
            course
            authenticityToken
            hideEditorActionCB
            updateCoursesCB
          />
        }
      }
      <div className="flex-1 flex flex-col bg-grey-lightest overflow-hidden">
        <div
          className="flex px-6 py-2 items-center justify-between overflow-y-scroll">
          <button
            className="max-w-md w-full flex mx-auto items-center justify-center relative bg-grey-lighter hover:bg-grey-light hover:shadow-md border-2 border-dashed p-6 rounded-lg mt-20 cursor-pointer"
            onClick={_ => send(UpdateEditorAction(ShowForm(None)))}>
            <i className="material-icons"> {"add_circle_outline" |> str} </i>
            <h4 className="font-semibold ml-2"> {"Add New Course" |> str} </h4>
          </button>
        </div>
        <div
          className="px-6 pb-4 mt-5 flex flex-1 bg-grey-lightest overflow-y-scroll">
          <div className="max-w-md w-full mx-auto relative">
            {
              state.courses
              |> Course.sort
              |> List.map(course =>
                   <div
                     className="flex items-center shadow bg-white rounded-lg overflow-hidden mb-4">
                     <div
                       className="flex w-full"
                       key={course |> Course.id |> string_of_int}>
                       <a
                         className="cursor-pointer flex flex-1 items-center py-4 px-4 hover:bg-grey-lighter"
                         onClick={
                           _ =>
                             send(
                               UpdateEditorAction(ShowForm(Some(course))),
                             )
                         }>
                         <div className="text-sm">
                           <span className="text-black font-semibold">
                             {course |> Course.name |> str}
                           </span>
                         </div>
                       </a>
                       <a
                         href={
                           "/school/courses/"
                           ++ (course |> Course.id |> string_of_int)
                           ++ "/students"
                         }
                         className="hover:bg-grey-lighter items-center p-4 flex cursor-pointer no-underline">
                         {"view" |> str}
                       </a>
                     </div>
                   </div>
                 )
              |> Array.of_list
              |> ReasonReact.array
            }
          </div>
        </div>
      </div>
    </div>;
  },
};

let decode = json =>
  Json.Decode.{
    authenticityToken: json |> field("authenticityToken", string),
  };

let jsComponent =
  ReasonReact.wrapReasonForJs(
    ~component,
    jsProps => {
      let props = jsProps |> decode;
      make(~authenticityToken=props.authenticityToken, [||]);
    },
  );