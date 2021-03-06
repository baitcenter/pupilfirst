# Exporting Data

PupilFirst has a robust data export feature that'll let you pull data out of the PupilFirst platform, and into a spreadsheet. This allows you to come up with your own analysis of the student data from a course.

![Course exports interface](https://res.cloudinary.com/sv-co/image/upload/v1574318122/pupilfirst_documentation/exporting_data/exports_page_aamvez.png)

To prepare a new export, visit the _Exports_ sub-menu within a course, and click the _Create a new export_ button. You have a few options to choose when preparing an export:

**Export only students with the following tags:**\
When preparing an export, you can limit the results to a select group of students by picking one or more tags that's associated with them.

**Which targets should the export include?**\
This defaults to _All targets_, but you can change it to _Only targets with reviewed submissions_, which will restrict the exported data to targets with submissions that are reviewed and graded by coaches.

Once you're happy with the options, click the _Create Export_ button.

## Exported data

The export may take a short while to prepare, so we'll send you an email when it's ready for download. The export is created as an `.ods` (OpenDocument Spreadsheet) file that contains three sheets: _Targets_, _Students_, and _Submissions_.

### Targets

This sheet includes a list of all _live_ targets in the course, ordered by level. The first column, `ID` is used to identify the target in the _Submissions_ sheet.

This sheet also includes the number of students who have submitted work on each target, the number of submissions pending review by a coach (where applicable), and the average grade on the target, for each evaluation criterion.

### Students

This is the list of active students requested in the export, and contains their personal details and tags. The first column, `Email Address`, will be used to identify the student in the _Submissions_ sheet.

Similar to the _Targets_ sheet, this sheet also includes the average grade received by the student grouped by evaluation criteria.

### Submissions

This contains a list of all submissions from requested students for all the targets. Students are on the Y-axis, and targets are on the X-axis. The result of a target can be one of a couple of values depending on the _type_ of target.

1. A blank cell indicates an target that hasn't been attempted.
2. A check-mark (`✓`) indicates a target that is marked as complete, or completed by visiting a link.
3. A fraction (`1/3`) indicates the result of a quiz.
4. A colored cell with a grade (`3`) indicates the grade given to a reviewed target.
   - If there are multiple evaluation criteria, each grade will be comma-separated, with criteria in alphabetical order.
   - If the student receieved a passing grade, the cell will have a green background. Otherwise, the background will be red.
5. The string `RP`, with a yellow background indicates that the student has submitted work, but that its **r**eview is **p**ending.

If a student has submitted work on a target more than once, then the cell will include that data as well. For example, if there is a target with two evaluation criteria, and a student has submitted twice, then the data might look like this: `1,2;2,3`, where `1,2` is the grading for the first submission and `2,3`, for the second.

## How to use exports

While working with PupilFirst as school admins, we've realized that it's quite difficult (if not impossible) to predict the kind of analyses you'll want to perform ahead of time. On the other hand, if you can access the data on your students as a spreadsheets, it's often trivial to come up with new analyses by creating new formalae within a spreadsheet application.

You can use the data in the spreadsheet to generate all kinds of reports. For example:

1. Track the trend of overall student performance within a course, over time.
2. Track how well your coaches are able to keep up with their reviewing workload.
3. Determine which optional targets are most popular among students.

These are just a few tasks that we've used the exported data for. We're sure that there are many other use-cases for the data that we haven't thought of yet.

## Moving common analyses into the platform

As an admin, if you notice that you're repeatedly performing the same kind of analysis using exported spreadsheets, then it may be a candidate for inclusion as a feature within the platform. [We'd love to talk](mailto:support@pupilfirst.com) about improving the anayltics features of PupilFirst.

An example of a metric we've included using a similar process is the _average grade_ displayed within the student's report page. This is a number that is easy to calculate from the grades present in the spreadsheet, but was included in the report page because of its obvious utility and the ease with which it could be implemented within the platform.
