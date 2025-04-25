// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import "package:http/http.dart" as http;

// List<Clase>? _courselist;
GoogleUser? googleUser;
GoogleSignInAccount? googleSignInAccount;
GoogleSignInAuthentication? googleAuth;
String webApiKey = '';
String androidApiKey = '';
String? apiKey;
GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: <String>[
    // "email",
    "https://mail.google.com/",
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/gmail.modify",
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/gmail.metadata",
    "https://www.googleapis.com/auth/drive",
    // "https://www.googleapis.com/auth/documents",
    // "https://www.googleapis.com/auth/spreadsheets",
    // "https://www.googleapis.com/auth/presentations",
    // "https://www.googleapis.com/auth/contacts",
    // "https://www.googleapis.com/auth/contacts.readonly",
    // "https://www.googleapis.com/auth/directory.readonly",
    // "https://www.googleapis.com/auth/admin.directory.user",
    // "https://www.googleapis.com/auth/admin.directory.group",
    // "https://www.googleapis.com/auth/classroom.coursework.students",
    // "https://www.googleapis.com/auth/classroom.courses",
    // "https://www.googleapis.com/auth/classroom.announcements",
    // "https://www.googleapis.com/auth/classroom.rosters",
    // "https://www.googleapis.com/auth/classroom.profile.emails",
    // "https://www.googleapis.com/auth/classroom.profile.photos",
    "https://www.googleapis.com/auth/firebase",
    "https://www.googleapis.com/auth/datastore",
    // "https://www.googleapis.com/auth/cloud-platform",
    // "https://www.googleapis.com/auth/devstorage.full_control",
    // "https://www.googleapis.com/auth/calendar",
    // "https://www.googleapis.com/auth/profile.agerange.read",
    // "https://www.googleapis.com/auth/profile.emails.read",
    // "https://www.googleapis.com/auth/profile.language.read",
    // "https://www.googleapis.com/auth/user.addresses.read",
    // "https://www.googleapis.com/auth/user.birthday.read",
    // "https://www.googleapis.com/auth/user.emails.read",
    // "https://www.googleapis.com/auth/user.gender.read",
    // "https://www.googleapis.com/auth/user.organization.read",
    // "https://www.googleapis.com/auth/user.phonenumbers.read",
    // "https://www.googleapis.com/auth/userinfo.email",
    // "https://www.googleapis.com/auth/userinfo.profile",
  ],
  // hostedDomain: "lreginaldofischione.edu.co",
);

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;

  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

Future<String?> getGoogleAccessToken() async {
  try {
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      return googleAuth.accessToken; // Este es el token de acceso de Google
    }
  } catch (error) {
    if (kDebugMode) {
      print("Error al obtener el token de acceso de Google: $error");
    }
  }
  return null;
}

enum CourseStates { ACTIVE, ARCHIVED, PROVISIONED, DECLINED, SUSPENDED }

enum UpdateMaskt {
  name,
  section,
  descriptionHeading,
  description,
  room,
  courseState,
  ownerId,
}

enum AssigneeMode {
  ASSIGNEE_MODE_UNSPECIFIED,
  ALL_STUDENTS,
  INDIVIDUAL_STUDENTS,
}

enum CourseWorkType {
  COURSE_WORK_TYPE_UNSPECIFIED,
  ASSIGNMENT,
  SHORT_ANSWER_QUESTION,
  MULTIPLE_CHOICE_QUESTION,
}

enum ShareModet {
  UNKNOWN_SHARE_MODE,
  VIEW,
  EDIT,
  STUDENT_COPY,
}

enum AnnouncementState {
  ANNOUNCEMENT_STATE_UNSPECIFIED,
  PUBLISHED,
  DRAFT,
  DELETED,
}

/// Clases para construir los parametros para consultar a la API de classroom

class CourseWork {
  String? courseId;
  String? id;
  String? title;
  String? description;
  List<CourseMaterial>? materials;
  String? state;
  String? alternateLink;
  String? creationTime;
  String? updateTime;
  DueDate? dueDate;
  DueTime? dueTime;
  String? scheduledTime;
  int? maxPoints;
  String? workType;
  bool? associatedWithDeveloper;
  String? assigneeMode;
  IndividualStudentsOptions? individualStudentsOptions;
  String? submissionModificationMode;
  String? creatorUserId;
  String? topicId;
  GradeCategory? gradeCategory;
  Assignment? assignment;
  MultipleChoiceQuestion? multipleChoiceQuestion;

  CourseWork({
    this.courseId,
    this.id,
    this.title,
    this.description,
    this.materials,
    this.state,
    this.alternateLink,
    this.creationTime,
    this.updateTime,
    this.dueDate,
    this.dueTime,
    this.scheduledTime,
    this.maxPoints,
    this.workType,
    this.associatedWithDeveloper,
    this.assigneeMode,
    this.individualStudentsOptions,
    this.submissionModificationMode,
    this.creatorUserId,
    this.topicId,
    this.gradeCategory,
    this.assignment,
    this.multipleChoiceQuestion,
  });

  CourseWork.fromJson(Map<String, dynamic> json) {
    List<CourseMaterial>? tMaterials = [];
    DueDate? tDueDate;
    DueTime? tDueTime;
    IndividualStudentsOptions? tIndividualStudentsOptions;
    GradeCategory? tGradeCategory;
    Assignment? tAssignment;
    MultipleChoiceQuestion? tMultipleChoiceQuestion;
    try {
      if (json['materials'] != null) {
        for (var m in json['materials']) {
          tMaterials.add(CourseMaterial.fromJson(m));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(['Error en json.materials', e, json['materials']]);
      }
    }
    try {
      if (json['dueDate'] != null) {
        tDueDate = DueDate.fromJson(json['dueDate']);
      }
    } catch (e) {
      if (kDebugMode) {
        print(['Error en json.dueDate', e, json['dueDate']]);
      }
    }
    try {
      if (json['dueTime'] != null) {
        tDueTime = DueTime.fromJson(json['dueTime']);
      }
    } catch (e) {
      if (kDebugMode) {
        print(['Error en json.dueTime', e, json['dueTime']]);
      }
    }
    try {
      if (json['individualStudentsOptions'] != null) {
        tIndividualStudentsOptions =
            IndividualStudentsOptions.fromJson(json['individualStudentsOptions']);
      }
    } catch (e) {
      if (kDebugMode) {
        print(['Error en json.individualStudentsOptions', e, json['individualStudentsOptions']]);
      }
    }
    try {
      if (json['gradeCategory'] != null) {
        tGradeCategory = GradeCategory.fromJson(json['gradeCategory']);
      }
    } catch (e) {
      if (kDebugMode) {
        print(['Error en json.gradeCategory', e, json['gradeCategory']]);
      }
    }
    try {
      if (json['assignment'] != null) {
        tAssignment = Assignment.fromJson(json['assignment']);
      }
    } catch (e) {
      if (kDebugMode) {
        print(['Error en json.assignment', e, json['assignment']]);
      }
    }
    try {
      if (json['multipleChoiceQuestion'] != null) {
        tMultipleChoiceQuestion = MultipleChoiceQuestion.fromJson(json['multipleChoiceQuestion']);
      }
    } catch (e) {
      if (kDebugMode) {
        print(['Error en json.multipleChoiceQuestion', e, json['multipleChoiceQuestion']]);
      }
    }
    try {
      courseId = json['courseId'];
      id = json['id'];
      title = json['title'];
      description = json['description'];
      materials = tMaterials;
      //json['materials'].cast<CourseMaterial>();
      state = json['state'];
      alternateLink = json['alternateLink'];
      creationTime = json['creationTime'];
      updateTime = json['updateTime'];
      dueDate = tDueDate;
      dueTime = tDueTime;
      scheduledTime = json['scheduledTime'];
      maxPoints = json['maxPoints'];
      workType = json['workType'];
      associatedWithDeveloper = json['associatedWithDeveloper'];
      assigneeMode = json['assigneeMode'];
      individualStudentsOptions = tIndividualStudentsOptions;
      submissionModificationMode = json['submissionModificationMode'];
      creatorUserId = json['creatorUserId'];
      topicId = json['topicId'];
      gradeCategory = tGradeCategory;
      assignment = tAssignment;
      multipleChoiceQuestion = tMultipleChoiceQuestion;
    } catch (e) {
      if (kDebugMode) {
        print(['Error en CourseWork.fromJson', e, json]);
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (data['courseId'] != null) {
      data['courseId'] = courseId;
    }
    if (data['id'] != null) {
      data['id'] = id;
    }
    if (data['title'] != null) {
      data['title'] = title;
    }
    if (data['description'] != null) {
      data['description'] = description;
    }
    if (data['materials'] != null) {
      data['materials'] = materials;
    }
    if (data['state'] != null) {
      data['state'] = state;
    }
    if (data['alternateLink'] != null) {
      data['alternateLink'] = alternateLink;
    }
    if (data['creationTime'] != null) {
      data['creationTime'] = creationTime;
    }
    if (data['updateTime'] != null) {
      data['updateTime'] = updateTime;
    }
    if (data['dueDate'] != null) {
      data['dueDate'] = dueDate;
    }
    if (data['dueTime'] != null) {
      data['dueTime'] = dueTime;
    }
    if (data['scheduledTime'] != null) {
      data['scheduledTime'] = scheduledTime;
    }
    if (data['maxPoints'] != null) {
      data['maxPoints'] = maxPoints;
    }
    if (data['workType'] != null) {
      data['workType'] = workType;
    }
    if (data['associatedWithDeveloper'] != null) {
      data['associatedWithDeveloper'] = associatedWithDeveloper;
    }
    if (data['assigneeMode'] != null) {
      data['assigneeMode'] = assigneeMode;
    }
    if (data['individualStudentsOptions'] != null) {
      data['individualStudentsOptions'] = individualStudentsOptions;
    }
    if (data['submissionModificationMode'] != null) {
      data['submissionModificationMode'] = submissionModificationMode;
    }
    if (data['creatorUserId'] != null) {
      data['creatorUserId'] = creatorUserId;
    }
    if (data['topicId'] != null) {
      data['topicId'] = topicId;
    }
    if (data['gradeCategory'] != null) {
      data['gradeCategory'] = gradeCategory;
    }
    if (data['assignment'] != null) {
      data['assignment'] = assignment;
    }
    if (data['multipleChoiceQuestion'] != null) {
      data['multipleChoiceQuestion'] = multipleChoiceQuestion;
    }
    return data;
  }
}

class StudentSubmission {
  String? courseId;
  String? courseWorkId;
  String? id;
  String? userId;
  String? creationTime;
  String? updateTime;
  String?
      state; // This could be an enum or string depending on the implementation of SubmissionState
  bool? late;
  double? draftGrade;
  double? assignedGrade;
  String? rubricId;
  Map<String, RubricGrade>? draftRubricGrades; // The structure depends on RubricGrade
  Map<String, RubricGrade>? assignedRubricGrades; // The structure depends on RubricGrade
  String? alternateLink;
  String?
      courseWorkType; // This could be an enum or string depending on the implementation of CourseWorkType
  bool? associatedWithDeveloper;
  List<SubmissionHistory>? submissionHistory; // The structure depends on SubmissionHistory
  String?
      previewVersion; // This could be an enum or string depending on the implementation of PreviewVersion

  // Fields for union field content
  AssignmentSubmission? assignmentSubmission; // The structure depends on AssignmentSubmission
  ShortAnswerSubmission? shortAnswerSubmission; // The structure depends on ShortAnswerSubmission
  MultipleChoiceSubmission?
      multipleChoiceSubmission; // The structure depends on MultipleChoiceSubmission

  StudentSubmission({
    this.courseId,
    this.courseWorkId,
    this.id,
    this.userId,
    this.creationTime,
    this.updateTime,
    this.state,
    this.late,
    this.draftGrade,
    this.assignedGrade,
    this.rubricId,
    this.draftRubricGrades,
    this.assignedRubricGrades,
    this.alternateLink,
    this.courseWorkType,
    this.associatedWithDeveloper,
    this.submissionHistory,
    this.previewVersion,
    this.assignmentSubmission,
    this.shortAnswerSubmission,
    this.multipleChoiceSubmission,
  });

  // Método fromJson
  factory StudentSubmission.fromJson(Map<String, dynamic> json) {
    return StudentSubmission(
      courseId: json['courseId'],
      courseWorkId: json['courseWorkId'],
      id: json['id'],
      userId: json['userId'],
      creationTime: json['creationTime'],
      updateTime: json['updateTime'],
      state: json['state'],
      late: json['late'],
      draftGrade: json['draftGrade']?.toDouble(),
      assignedGrade: json['assignedGrade']?.toDouble(),
      rubricId: json['rubricId'],
      draftRubricGrades: (json['draftRubricGrades'] != null)
          ? (json['draftRubricGrades'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, RubricGrade.fromJson(value)))
          : null,
      assignedRubricGrades: (json['assignedRubricGrades'] != null)
          ? (json['assignedRubricGrades'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, RubricGrade.fromJson(value)))
          : null,
      alternateLink: json['alternateLink'],
      courseWorkType: json['courseWorkType'],
      associatedWithDeveloper: json['associatedWithDeveloper'],
      submissionHistory: (json['submissionHistory'] != null)
          ? (json['submissionHistory'] as List<dynamic>?)
              ?.map((e) => SubmissionHistory.fromJson(e))
              .toList()
          : null,
      previewVersion: json['previewVersion'],
      assignmentSubmission: json['assignmentSubmission'] != null
          ? AssignmentSubmission.fromJson(json['assignmentSubmission'])
          : null,
      shortAnswerSubmission: json['shortAnswerSubmission'] != null
          ? ShortAnswerSubmission.fromJson(json['shortAnswerSubmission'])
          : null,
      multipleChoiceSubmission: json['multipleChoiceSubmission'] != null
          ? MultipleChoiceSubmission.fromJson(json['multipleChoiceSubmission'])
          : null,
    );
  }

  // Método toJson
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['courseId'] = courseId;
    data['courseWorkId'] = courseWorkId;
    data['id'] = id;
    data['userId'] = userId;
    data['creationTime'] = creationTime;
    data['updateTime'] = updateTime;
    data['state'] = state;
    data['late'] = late;
    data['draftGrade'] = draftGrade;
    data['assignedGrade'] = assignedGrade;
    data['rubricId'] = rubricId;
    if (draftRubricGrades != null) {
      data['draftRubricGrades'] =
          draftRubricGrades!.map((key, value) => MapEntry(key, value.toJson()));
    }
    if (assignedRubricGrades != null) {
      data['assignedRubricGrades'] =
          assignedRubricGrades!.map((key, value) => MapEntry(key, value.toJson()));
    }
    data['alternateLink'] = alternateLink;
    data['courseWorkType'] = courseWorkType;
    data['associatedWithDeveloper'] = associatedWithDeveloper;
    if (submissionHistory != null) {
      data['submissionHistory'] = submissionHistory!.map((e) => e.toJson()).toList();
    }
    data['previewVersion'] = previewVersion;
    if (assignmentSubmission != null) {
      data['assignmentSubmission'] = assignmentSubmission!.toJson();
    }
    if (shortAnswerSubmission != null) {
      data['shortAnswerSubmission'] = shortAnswerSubmission!.toJson();
    }
    if (multipleChoiceSubmission != null) {
      data['multipleChoiceSubmission'] = multipleChoiceSubmission!.toJson();
    }

    return data;
  }
}

class MultipleChoiceSubmission {
  String? answer;

  MultipleChoiceSubmission({
    this.answer,
  });

  MultipleChoiceSubmission.fromJson(Map<String, dynamic> json) {
    answer = json['answer'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (answer != null) {
      data['answer'] = answer;
    }
    return data;
  }
}

class ShortAnswerSubmission {
  String? answer;

  ShortAnswerSubmission({
    this.answer,
  });

  ShortAnswerSubmission.fromJson(Map<String, dynamic> json) {
    answer = json['answer'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (answer != null) {
      data['answer'] = answer;
    }
    return data;
  }
}

class AssignmentSubmission {
  List<CourseMaterial>? attachments;

  AssignmentSubmission({
    this.attachments,
  });

  AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    List<CourseMaterial>? tAttachments;
    try {
      if (json['attachments'] != null) {
        tAttachments = [];
        for (var m in json['attachments']) {
          tAttachments.add(CourseMaterial.fromJson(m));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(['Error en json.attachments', e, json['attachments']]);
      }
    }
    attachments = tAttachments;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (attachments != null) {
      data['attachments'] = attachments;
    }
    return data;
  }
}

class SubmissionHistory {
  StateHistory? stateHistory;
  GradeHistory? gradeHistory;

  SubmissionHistory({
    this.stateHistory,
    this.gradeHistory,
  });

  SubmissionHistory.fromJson(Map<String, dynamic> json) {
    StateHistory? tStateHistory;
    GradeHistory? tGradeHistory;
    try {
      if (json['stateHistory'] != null) {
        tStateHistory = StateHistory.fromJson(json['stateHistory']);
      }
    } catch (e) {
      if (kDebugMode) {
        print(['Error en json.stateHistory', e, json['stateHistory']]);
      }
    }
    try {
      if (json['gradeHistory'] != null) {
        tGradeHistory = GradeHistory.fromJson(json['gradeHistory']);
      }
    } catch (e) {
      if (kDebugMode) {
        print(['Error en json.gradeHistory', e, json['gradeHistory']]);
      }
    }
    stateHistory = tStateHistory;
    gradeHistory = tGradeHistory;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (stateHistory != null) {
      data['stateHistory'] = stateHistory;
    }
    if (gradeHistory != null) {
      data['gradeHistory'] = gradeHistory;
    }
    return data;
  }
}

class GradeHistory {
  int? pointsEarned;
  int? maxPoints;
  String? gradeTimestamp;
  String? actorUserId;
  String? gradeChangeType;

  GradeHistory({
    this.pointsEarned,
    this.maxPoints,
    this.gradeTimestamp,
    this.actorUserId,
    this.gradeChangeType,
  });

  GradeHistory.fromJson(Map<String, dynamic> json) {
    pointsEarned = json['pointsEarned'];
    maxPoints = json['maxPoints'];
    gradeTimestamp = json['gradeTimestamp'];
    actorUserId = json['actorUserId'];
    gradeChangeType = json['gradeChangeType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (pointsEarned != null) {
      data['pointsEarned'] = pointsEarned;
    }
    if (maxPoints != null) {
      data['maxPoints'] = maxPoints;
    }
    if (gradeTimestamp != null) {
      data['gradeTimestamp'] = gradeTimestamp;
    }
    if (actorUserId != null) {
      data['actorUserId'] = actorUserId;
    }
    if (gradeChangeType != null) {
      data['gradeChangeType'] = gradeChangeType;
    }
    return data;
  }
}

class StateHistory {
  String? state;
  String? stateTimestamp;
  String? actorUserId;

  StateHistory({this.state, this.stateTimestamp, this.actorUserId});

  StateHistory.fromJson(Map<String, dynamic> json) {
    state = json['state'];
    stateTimestamp = json['stateTimestamp'];
    actorUserId = json['actorUserId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (state != null) {
      data['state'] = state;
    }
    if (stateTimestamp != null) {
      data['stateTimestamp'] = stateTimestamp;
    }
    if (actorUserId != null) {
      data['actorUserId'] = actorUserId;
    }
    return data;
  }
}

class RubricGrade {
  String? criterionId;
  String? levelId;
  int? points;

  RubricGrade({this.criterionId, this.levelId, this.points});

  RubricGrade.fromJson(Map<String, dynamic> json) {
    criterionId = json['criterionId'];
    levelId = json['levelId'];
    points = json['points'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (criterionId != null) {
      data['criterionId'] = criterionId;
    }
    if (levelId != null) {
      data['levelId'] = levelId;
    }
    if (points != null) {
      data['points'] = points;
    }
    return data;
  }
}

class DueDate {
  int? year;
  int? month;
  int? day;

  DueDate({this.year, this.month, this.day});

  DueDate.fromJson(Map<String, dynamic> json) {
    year = json['year'];
    month = json['month'];
    day = json['day'];
  }

  DateTime getDate() {
    if (year == null) {
      throw Exception('Year is required to create a DateTime');
    }
    // Usa el primer mes y día como valores por defecto si son nulos
    int effectiveMonth = month ?? 1;
    int effectiveDay = day ?? 1;

    return DateTime(year!, effectiveMonth, effectiveDay);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (year != null) {
      data['year'] = year;
    }
    if (month != null) {
      data['month'] = month;
    }
    if (day != null) {
      data['day'] = day;
    }
    return data;
  }
}

class DueTime {
  int? hours;
  int? minutes;
  int? seconds;
  int? nanos;

  DueTime({
    this.hours,
    this.minutes,
    this.seconds,
    this.nanos,
  });

  DueTime.fromJson(Map<String, dynamic> json) {
    hours = json['hours'];
    minutes = json['minutes'];
    seconds = json['seconds'];
    nanos = json['nanos'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (hours != null) {
      data['hours'] = hours;
    }
    if (minutes != null) {
      data['minutes'] = minutes;
    }
    if (seconds != null) {
      data['seconds'] = seconds;
    }
    if (nanos != null) {
      data['nanos'] = nanos;
    }
    return data;
  }
}

class GradeCategory {
  String? id;
  String? name;
  String? weight;
  String? defaultGradeDenominator;

  GradeCategory({this.id, this.name, this.weight, this.defaultGradeDenominator});

  GradeCategory.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    weight = json['weight'];
    defaultGradeDenominator = json['defaultGradeDenominator'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['weight'] = weight;
    data['defaultGradeDenominator'] = defaultGradeDenominator;
    return data;
  }
}

class Assignment {
  DriveFolder? studentWorkFolder;

  Assignment({this.studentWorkFolder});

  Assignment.fromJson(Map<String, dynamic> json) {
    studentWorkFolder = DriveFolder.fromJson(json['studentWorkFolder']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['studentWorkFolder'] = studentWorkFolder?.toJson();
    return data;
  }
}

class MultipleChoiceQuestion {
  List<String>? choices;

  MultipleChoiceQuestion({this.choices});

  MultipleChoiceQuestion.fromJson(Map<String, dynamic> json) {
    choices = json['choices'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['choices'] = choices;
    return data;
  }
}

class CourseRequestParam {
  String? key;
  String? alias;
  String? courseId;
  String? studentId;
  String? teacherId;
  String? courseStates;
  String? pageToken;
  String? pageSize;
  String? updateMask;
  dynamic requestBody;

  CourseRequestParam({
    this.key,
    this.alias,
    this.courseId,
    this.studentId,
    this.teacherId,
    this.courseStates,
    this.pageToken,
    this.pageSize,
    this.updateMask,
    this.requestBody,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    if (courseStates != null) {
      data['courseStates'] = courseStates;
    }
    if (alias != null) {
      data['alias'] = alias;
    }
    if (courseId != null) {
      data['courseId'] = courseId;
    }
    if (studentId != null) {
      data['studentId'] = studentId;
    }
    if (teacherId != null) {
      data['teacherId'] = teacherId;
    }
    if (pageToken != null) {
      data['pageToken'] = pageToken;
    }
    if (pageSize != null) {
      data['pageSize'] = pageSize;
    }
    if (updateMask != null) {
      data['updateMask'] = updateMask;
    }
    if (requestBody != null) {
      data['requestBody'] = requestBody;
    }
    data['key'] = key;
    return data;
  }
}

class CourseList {
  String? key;
  String? courseId;
  String? studentId;
  String? teacherId;
  String? courseStates;
  String? pageToken;
  String? pageSize;

  CourseList({
    this.key,
    this.courseId,
    this.studentId,
    this.teacherId,
    this.courseStates,
    this.pageToken,
    this.pageSize,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (courseId != null) {
      data['courseId'] = courseId;
    }
    if (studentId != null) {
      data['studentId'] = studentId;
    }
    if (teacherId != null) {
      data['teacherId'] = teacherId;
    }
    if (courseStates != null) {
      data['courseStates'] = courseStates;
    }
    if (pageToken != null) {
      data['pageToken'] = pageToken;
    }
    if (pageSize != null) {
      data['pageSize'] = pageSize;
    }
    data['key'] = key;
    return data;
  }
}

class CourseStudentsList {
  String? key;
  String? courseId;
  String? pageToken;
  String? pageSize;
  CourseStudentsList({
    this.key,
    this.courseId,
    this.pageToken,
    this.pageSize,
  });
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (pageToken != null) {
      data['pageToken'] = pageToken;
    }
    if (pageSize != null) {
      data['pageSize'] = pageSize;
    }
    data['key'] = key;
    return data;
  }
}

class CourseAlias {
  String? alias;

  CourseAlias({this.alias});

  CourseAlias.fromJson(Map<String, dynamic> json) {
    alias = json['alias'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['alias'] = alias;
    return data;
  }
}

class UpdateMask {
  UpdateMaskt? updateMask;

  UpdateMask({@required this.updateMask});

  UpdateMask.fromIndex(int index) {
    // Get enum from index
    updateMask = UpdateMaskt.values[index];
  }

  UpdateMask.fromString(String a) {
    // Get enum from index
    for (var e in UpdateMaskt.values) {
      if (e.toString() == a) {
        updateMask = e;
      }
    }
  }

  bool canLend(UpdateMaskt type) {
    if (type == updateMask) {
      return true;
    }
    return false;
  }

  int get updateMaskIndex {
    return updateMask!.index;
  }
}

class DriveFile {
  String? id;
  String? title;
  String? alternateLink;
  String? thumbnailUrl;

  DriveFile({this.id, this.title, this.alternateLink, this.thumbnailUrl});

  DriveFile.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    alternateLink = json['alternateLink'];
    thumbnailUrl = json['thumbnailUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['alternateLink'] = alternateLink;
    data['thumbnailUrl'] = thumbnailUrl;
    return data;
  }
}

class DriveFolder {
  String? id;
  String? title;
  String? alternateLink;

  DriveFolder({
    this.id,
    this.title,
    this.alternateLink,
  });

  DriveFolder.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    alternateLink = json['alternateLink'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['alternateLink'] = alternateLink;
    return data;
  }
}

class GoogleForm {
  String? formUrl;
  String? responseUrl;
  String? title;
  String? thumbnailUrl;

  GoogleForm({this.formUrl, this.responseUrl, this.title, this.thumbnailUrl});

  GoogleForm.fromJson(Map<String, dynamic> json) {
    formUrl = json['formUrl'];
    responseUrl = json['responseUrl'];
    title = json['title'];
    thumbnailUrl = json['thumbnailUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['formUrl'] = formUrl;
    data['responseUrl'] = responseUrl;
    data['title'] = title;
    data['thumbnailUrl'] = thumbnailUrl;
    return data;
  }
}

class IndividualStudentsOptions {
  List<String>? studentIds;

  IndividualStudentsOptions({this.studentIds});

  IndividualStudentsOptions.fromJson(Map<String, dynamic> json) {
    studentIds = json['studentIds'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['studentIds'] = studentIds;
    return data;
  }
}

class GoogleLink {
  String? url;
  String? title;
  String? thumbnailUrl;

  GoogleLink({this.url, this.title, this.thumbnailUrl});

  GoogleLink.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    title = json['title'];
    thumbnailUrl = json['thumbnailUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = url;
    data['title'] = title;
    data['thumbnailUrl'] = thumbnailUrl;
    return data;
  }
}

class ShareMode {
  ShareModet? shareMode;

  ShareMode({@required this.shareMode});

  ShareMode.fromIndex(int index) {
    // Get enum from index
    shareMode = ShareModet.values[index];
  }

  ShareMode.fromString(String a) {
    // Get enum from index
    for (var e in ShareModet.values) {
      if (e.toString() == a) {
        shareMode = e;
      }
    }
  }

  bool canLend(ShareModet type) {
    if (type == shareMode) {
      return true;
    }
    return false;
  }

  int get shareModeIndex {
    return shareMode!.index;
  }
}

class SharedDriveFile {
  DriveFolder? driveFolder;
  ShareMode? shareMode;

  SharedDriveFile({
    this.driveFolder,
    this.shareMode,
  });

  SharedDriveFile.fromJson(Map<String, dynamic> json) {
    driveFolder = json['driveFolder'] != null ? DriveFolder.fromJson(json['driveFolder']) : null;
    shareMode = json['shareMode'] != null ? ShareMode.fromString(json['shareMode']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (driveFolder != null) {
      data['driveFolder'] = driveFolder!.toJson();
    }
    if (shareMode != null) {
      data['shareMode'] = shareMode;
    }
    return data;
  }
}

class YouTubeVideo {
  String? id;
  String? title;
  String? alternateLink;
  String? thumbnailUrl;

  YouTubeVideo({this.id, this.title, this.alternateLink, this.thumbnailUrl});

  YouTubeVideo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    alternateLink = json['alternateLink'];
    thumbnailUrl = json['thumbnailUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['alternateLink'] = alternateLink;
    data['thumbnailUrl'] = thumbnailUrl;
    return data;
  }
}

class CourseMaterial {
  SharedDriveFile? driveFile;
  YouTubeVideo? youtubeVideo;
  GoogleLink? link;
  GoogleForm? form;

  CourseMaterial({
    this.driveFile,
    this.youtubeVideo,
    this.link,
    this.form,
  });

  CourseMaterial.fromJson(Map<String, dynamic> json) {
    driveFile = json['driveFile'] != null ? SharedDriveFile.fromJson(json['driveFile']) : null;
    youtubeVideo =
        json['youtubeVideo'] != null ? YouTubeVideo.fromJson(json['youtubeVideo']) : null;
    link = json['link'] != null ? GoogleLink.fromJson(json['link']) : null;
    form = json['form'] != null ? GoogleForm.fromJson(json['form']) : null;
  }
}

class ModifyIndividualStudentsOptions {
  List<String>? addStudentIds;
  List<String>? removeStudentIds;

  ModifyIndividualStudentsOptions({this.addStudentIds, this.removeStudentIds});

  ModifyIndividualStudentsOptions.fromJson(Map<String, dynamic> json) {
    addStudentIds = json['addStudentIds'].cast<String>();
    removeStudentIds = json['removeStudentIds'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['addStudentIds'] = addStudentIds;
    data['removeStudentIds'] = removeStudentIds;
    return data;
  }
}

/// Classroom API interface

// class ClassroomApi {
//   Courses? courses;
//   ClassroomApi() {
//     courses = Courses();
//   }
// }

// class Courses {
//   // Clase clase;
//   // Function delete;
//   // Function get;
//   // Function patch;
//   // Function update;
//   Courses();

//   create(Clase clase) async {
//     // Clase clase = Clase.fromClassroom(param.requestBody);
//     var parameters = clase.toClassroom();
//     var url =
//         Uri.https('classroom.googleapis.com', '/v1/courses', {'key': apiKey});
//     await postHttp(parameters, url).then((course0) async {
//       try {
//         Clase curso = Clase.fromClassroom(course0);
//         // print([DateTime.now(), 'Curso creado', curso.name, curso.id]);
//         return curso;
//       } catch (e) {
//         if (kDebugMode) {
//           print([
//             'Error en create curso',
//             clase.name,
//             e,
//             clase.toClassroom(),
//             course0
//           ]);
//         }
//         rethrow;
//       }
//     });
//   }

//   list(CourseList param) async {
//     Uri url;
//     try {
//       if (param.pageToken == null) {
//         _courselist = [];
//       }
//       url =
//           Uri.https('classroom.googleapis.com', '/v1/courses/', param.toJson());
//       return await getHttp(url).then((rta) async {
//         if (kDebugMode) {
//           print(['ClassroomApi.courses.list rta', rta]);
//         }
//         if (rta["courses"] != null) {
//           // print(rta["courses"]);
//           for (var est in rta["courses"]) {
//             _courselist!.add(Clase.fromClassroom(est));
//           }
//           if (rta['nextPageToken'] != null) {
//             param.pageToken = rta['nextPageToken'];
//             list(param);
//           }
//           // print(['List clases', _courselist!.length]);
//           return _courselist;
//         }
//       });
//     } catch (e) {
//       if (kDebugMode) {
//         print(['Error en ClassroomApi.courses.list', e]);
//       }
//     }
//   }
// }

/// Google User
class GoogleUser {
  String? kind;
  String? id;
  String? etag;
  String? grupo;
  String? primaryEmail;
  Name? name;
  bool? isAdmin;
  bool? isDelegatedAdmin;
  String? lastLoginTime;
  String? creationTime;
  bool? agreedToTerms;
  bool? suspended;
  bool? archived;
  bool? changePasswordAtNextLogin;
  bool? ipWhitelisted;
  List<Emails>? emails;
  List<Organizations>? organizations;
  List<String>? nonEditableAliases;
  String? customerId;
  String? orgUnitPath;
  bool? isMailboxSetup;
  bool? isEnrolledIn2Sv;
  bool? isEnforcedIn2Sv;
  bool? includeInGlobalAddressList;
  bool? selected;
  String? thumbnailPhotoUrl;
  String? thumbnailPhotoEtag;

  GoogleUser({
    this.kind,
    this.id,
    this.etag,
    this.grupo,
    this.primaryEmail,
    this.name,
    this.isAdmin,
    this.isDelegatedAdmin,
    this.lastLoginTime,
    this.creationTime,
    this.agreedToTerms,
    this.suspended,
    this.archived,
    this.changePasswordAtNextLogin,
    this.ipWhitelisted,
    this.emails,
    this.organizations,
    this.nonEditableAliases,
    this.customerId,
    this.orgUnitPath,
    this.isMailboxSetup,
    this.isEnrolledIn2Sv,
    this.isEnforcedIn2Sv,
    this.includeInGlobalAddressList,
    this.selected,
    this.thumbnailPhotoUrl,
    this.thumbnailPhotoEtag,
  });

  GoogleUser.fromJson(Map<String, dynamic> json) {
    if (json['kind'] != null) {
      kind = json['kind'];
    }
    if (json['id'] != null) {
      id = json['id'];
    }
    if (json['etag'] != null) {
      etag = json['etag'];
    }
    if (json['primaryEmail'] != null) {
      primaryEmail = json['primaryEmail'];
    }
    name = json['name'] != null ? Name.fromJson(json['name']) : null;
    if (json['isAdmin'] != null) {
      isAdmin = json['isAdmin'];
    }
    if (json['isDelegatedAdmin'] != null) {
      isDelegatedAdmin = json['isDelegatedAdmin'];
    }
    if (json['lastLoginTime'] != null) {
      lastLoginTime = json['lastLoginTime'];
    }
    if (json['creationTime'] != null) {
      creationTime = json['creationTime'];
    }
    if (json['agreedToTerms'] != null) {
      agreedToTerms = json['agreedToTerms'];
    }
    if (json['suspended'] != null) {
      suspended = json['suspended'];
    }
    if (json['archived'] != null) {
      archived = json['archived'];
    }
    if (json['changePasswordAtNextLogin'] != null) {
      changePasswordAtNextLogin = json['changePasswordAtNextLogin'];
    }
    if (json['ipWhitelisted'] != null) {
      ipWhitelisted = json['ipWhitelisted'];
    }
    if (json['emails'] != null) {
      emails = <Emails>[];
      json['emails'].forEach((v) {
        emails!.add(Emails.fromJson(v));
      });
    }
    if (json['organizations'] != null) {
      organizations = <Organizations>[];
      json['organizations'].forEach((v) {
        organizations!.add(Organizations.fromJson(v));
      });
    }
    if (json['nonEditableAliases'] != null) {
      nonEditableAliases = json['nonEditableAliases'].cast<String>();
    }
    if (json['customerId'] != null) {
      customerId = json['customerId'];
    }
    if (json['orgUnitPath'] != null) {
      orgUnitPath = json['orgUnitPath'];
    }
    if (json['isMailboxSetup'] != null) {
      isMailboxSetup = json['isMailboxSetup'];
    }
    if (json['isEnrolledIn2Sv'] != null) {
      isEnrolledIn2Sv = json['isEnrolledIn2Sv'];
    }
    if (json['isEnforcedIn2Sv'] != null) {
      isEnforcedIn2Sv = json['isEnforcedIn2Sv'];
    }
    if (json['includeInGlobalAddressList'] != null) {
      includeInGlobalAddressList = json['includeInGlobalAddressList'];
    }
    selected = false;
    if (json['thumbnailPhotoUrl'] != null) {
      thumbnailPhotoUrl = json['thumbnailPhotoUrl'];
    }
    if (json['thumbnailPhotoEtag'] != null) {
      thumbnailPhotoEtag = json['thumbnailPhotoEtag'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['kind'] = kind;
    data['id'] = id;
    data['etag'] = etag;
    data['primaryEmail'] = primaryEmail;
    if (name != null) {
      data['name'] = name!.toJson();
    }
    data['isAdmin'] = isAdmin;
    data['isDelegatedAdmin'] = isDelegatedAdmin;
    data['lastLoginTime'] = lastLoginTime;
    data['creationTime'] = creationTime;
    data['agreedToTerms'] = agreedToTerms;
    data['suspended'] = suspended;
    data['archived'] = archived;
    data['changePasswordAtNextLogin'] = changePasswordAtNextLogin;
    data['ipWhitelisted'] = ipWhitelisted;
    if (emails != null) {
      data['emails'] = emails!.map((v) => v.toJson()).toList();
    }
    if (organizations != null) {
      data['organizations'] = organizations!.map((v) => v.toJson()).toList();
    }
    data['nonEditableAliases'] = nonEditableAliases;
    data['customerId'] = customerId;
    data['orgUnitPath'] = orgUnitPath;
    data['isMailboxSetup'] = isMailboxSetup;
    data['isEnrolledIn2Sv'] = isEnrolledIn2Sv;
    data['isEnforcedIn2Sv'] = isEnforcedIn2Sv;
    data['includeInGlobalAddressList'] = includeInGlobalAddressList;
    data['selected'] = selected;
    data['thumbnailPhotoUrl'] = thumbnailPhotoUrl;
    data['thumbnailPhotoEtag'] = thumbnailPhotoEtag;
    return data;
  }
}

class Name {
  String? givenName;
  String? familyName;
  String? fullName;

  Name({this.givenName, this.familyName, this.fullName});

  Name.fromJson(Map<dynamic, dynamic> json) {
    givenName = (json['givenName'] != null) ? json['givenName'] : null;
    familyName = (json['familyName'] != null) ? json['familyName'] : null;
    fullName = (json['fullName'] != null) ? json['fullName'] : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (givenName != null) {
      data['givenName'] = givenName.toString();
    }
    if (familyName != null) {
      data['familyName'] = familyName.toString();
    }
    if (fullName != null) {
      data['fullName'] = fullName.toString();
    }
    return data;
  }
}

class Emails {
  String? address;
  bool? primary;

  Emails({this.address, this.primary});

  // Emails.fromUser(admin.UserName userName) {
  //   fullName = userName.fullName;
  //   givenName = userName.givenName;
  //   familyName = userName.familyName;
  // }

  Emails.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    primary = json['primary'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    data['primary'] = primary;
    return data;
  }
}

class Organizations {
  String? title;
  bool? primary;
  String? customType;
  String? description;

  Organizations({this.title, this.primary, this.customType, this.description});

  Organizations.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    primary = json['primary'];
    customType = json['customType'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['primary'] = primary;
    data['customType'] = customType;
    data['description'] = description;
    return data;
  }
}

class Profile {
  String? id;
  Name? name;
  String? emailAddress;
  String? photoUrl;
  List? permissions;
  bool? verifiedTeacher;

  Profile({
    this.id,
    this.name,
    this.emailAddress,
    this.photoUrl,
    this.permissions,
    this.verifiedTeacher,
  });

  factory Profile.fromClassroom(Map<dynamic, dynamic> json) {
    Profile? a;
    // print(json);
    try {
      a = Profile(
        id: json['id'],
        name: Name.fromJson(json['name']),
        emailAddress: json['emailAddress'] ?? json['primaryEmail'],
        photoUrl: json['photoUrl'],
        permissions: json['permissions'],
        verifiedTeacher: (json['verifiedTeacher'] != null) ? json['verifiedTeacher'] : false,
      );
    } catch (e) {
      if (kDebugMode) {
        print(['Error en modelo de Profile.fromClassroom', e, json]);
      }
    }
    return a!;
  }
  // Nuevo método fromGoogleUser
  factory Profile.fromGoogleUser(GoogleUser user) {
    return Profile(
      id: user.id,
      name: user.name,
      emailAddress: user.primaryEmail,
      photoUrl: user.thumbnailPhotoUrl,
      permissions: [], // Los permisos pueden no ser directamente mapeables, por lo que se inicia vacío.
      verifiedTeacher:
          user.isAdmin ?? false, // Asumiendo isAdmin como indicador de un "profesor verificado".
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    // Map<String, dynamic>? name = this.name != null ? this.name!.toJson() : {};
    if (id != null) {
      data['id'] = id;
    }
    if (name != null) {
      data['name'] = name!.toJson();
    }
    if (emailAddress != null) {
      data['emailAddress'] = emailAddress;
    }
    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
    }
    if (permissions != null) {
      data['permissions'] = permissions;
    }
    if (verifiedTeacher != null) {
      data['verifiedTeacher'] = verifiedTeacher;
    }
    return data;
    /* return {
      'id': id,
      'name': name,
      'emailAddress': emailAddress,
      'photoUrl': photoUrl,
      'permissions': permissions,
      'verifiedTeacher': verifiedTeacher,
    }; */
  }

  dynamic get(String propertyName) {
    var mapRep = toJson();
    if (mapRep.containsKey(propertyName)) {
      return mapRep[propertyName];
    }
    throw ArgumentError('propery not found');
  }
}

class ClassroomUser {
  String? courseId;
  String? userId;
  Profile? profile;
  int? index;
  bool? selected;
  bool? editado;

  ClassroomUser({
    this.courseId,
    this.userId,
    this.profile,
    this.index,
    this.selected,
    this.editado,
  });

  factory ClassroomUser.fromClassroom(Map<dynamic, dynamic> json) {
    ClassroomUser? a;
    try {
      a = ClassroomUser(
        courseId: json['courseId'],
        userId: json['userId'],
        profile: Profile.fromClassroom(json['profile']),
        index: 0,
        selected: false,
        editado: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print(['Error en modelo de ClassroomUser.fromClassroom', e, json]);
      }
    }
    return a!;
  }

  Map toJson() {
    Map? profile;
    if (this.profile != null) {
      profile = this.profile!.toJson();
    } else {
      profile = null;
    }
    return {
      'courseId': courseId,
      'userId': userId,
      'profile': profile,
    };
  }

  dynamic get(String propertyName) {
    var mapRep = toJson();
    if (mapRep.containsKey(propertyName)) {
      return mapRep[propertyName];
    }
    throw ArgumentError('propery not found');
  }
}
// Google Calendar

/* {
  "kind": "calendar#calendarListEntry",
  "id": "string",
  "summary": "string",
  "description": "string",
  "location": "string",
  "timeZone": "string",
  "summaryOverride": "string",
  "colorId": "string",
  "backgroundColor": "string",
  "foregroundColor": "string",
  "hidden": true,
  "selected": true,
  "accessRole": "string",
  "defaultReminders": [
    {
      "method": "string",
      "minutes": 0
    }
  ],
  "notificationSettings": {
    "notifications": [
      {
        "type": "string",
        "method": "string"
      }
    ]
  },
  "primary": true,
  "deleted": true,
  "conferenceProperties": {
    "allowedConferenceSolutionTypes": [
      "string"
    ]
  }
} */
/* {
  "kind": "calendar#event",
  "id": "string", <============
  "status": "string", <============
  "htmlLink": "string",
  "created": "2019-01-14T15:20:10+01:00", <============
  "updated": "2019-01-14T15:20:10+01:00", <============
  "summary": "string", <============ nombre xx
  "description": "string", <============ xx
  "location": "string", <============ aula
  "colorId": "string", <============ xx
  "creator": { <============ docente
    "id": "string",
    "email": "string",
    "displayName": "string",
    "self": true
  },
  "organizer": {
    "id": "string",
    "email": "string",
    "displayName": "string",
    "self": true
  },
  "start": { <============
    "date": "2019-01-14T15:20:10+01:00",
    "dateTime": "2019-01-14T15:20:10+01:00",
    "timeZone": "string"
  },
  "end": { <============
    "date": "2019-01-14T15:20:10+01:00",
    "dateTime": "2019-01-14T15:20:10+01:00",
    "timeZone": "string"
  },
  "endTimeUnspecified": true,
  "recurrence": [
    "string"
  ],
  "recurringEventId": "string",
  "originalStartTime": {
    "date": "2019-01-14T15:20:10+01:00",
    "dateTime": "2019-01-14T15:20:10+01:00",
    "timeZone": "string"
  },
  "transparency": "string",
  "visibility": "string",
  "iCalUID": "string",
  "sequence": 0,
  "attendees": [
    {
      "id": "string",
      "email": "string",
      "displayName": "string",
      "organizer": true,
      "self": true,
      "resource": true,
      "optional": true,
      "responseStatus": "string",
      "comment": "string",
      "additionalGuests": 0
    }
  ],
  "attendeesOmitted": true,
  "extendedProperties": {
    "private": {
      (key): "string"
    },
    "shared": {
      (key): "string"
    }
  },
  "hangoutLink": "string",
  "conferenceData": {
    "createRequest": {
      "requestId": "string",
      "conferenceSolutionKey": {
        "type": "string"
      },
      "status": {
        "statusCode": "string"
      }
    },
    "entryPoints": [
      {
        "entryPointType": "string",
        "uri": "string",
        "label": "string",
        "pin": "string",
        "accessCode": "string",
        "meetingCode": "string",
        "passcode": "string",
        "password": "string"
      }
    ],
    "conferenceSolution": {
      "key": {
        "type": "string"
      },
      "name": "string",
      "iconUri": "string"
    },
    "conferenceId": "string",
    "signature": "string",
    "notes": "string",
  },
  "gadget": {
    "type": "string",
    "title": "string",
    "link": "string",
    "iconLink": "string",
    "width": 0,
    "height": 0,
    "display": "string",
    "preferences": {
      (key): "string"
    }
  },
  "anyoneCanAddSelf": true,
  "guestsCanInviteOthers": true,
  "guestsCanModify": true,
  "guestsCanSeeOtherGuests": true,
  "privateCopy": true,
  "locked": true,
  "reminders": {
    "useDefault": true,
    "overrides": [
      {
        "method": "string",
        "minutes": 0
      }
    ]
  },
  "source": {
    "url": "string",
    "title": "string"
  },
  "workingLocationProperties": {
    "type": "string",
    "homeOffice": (value),
    "customLocation": {
      "label": "string"
    },
    "officeLocation": {
      "buildingId": "string",
      "floorId": "string",
      "floorSectionId": "string",
      "deskId": "string",
      "label": "string"
    }
  },
  "outOfOfficeProperties": {
    "autoDeclineMode": "string",
    "declineMessage": "string"
  },
  "focusTimeProperties": {
    "autoDeclineMode": "string",
    "declineMessage": "string",
    "chatStatus": "string"
  },
  "attachments": [
    {
      "fileUrl": "string",
      "title": "string",
      "mimeType": "string",
      "iconLink": "string",
      "fileId": "string"
    }
  ],
  "eventType": "string" <============ xx
} */
class Calendar {
  String? kind;
  String? id;
  String? summary;
  String? description;
  String? location;
  String? timeZone;
  String? summaryOverride;
  String? colorId;
  String? backgroundColor;
  String? foregroundColor;
  bool? hidden;
  bool? selected;
  String? accessRole;
  List<DefaultReminders>? defaultReminders;
  NotificationSettings? notificationSettings;
  bool? primary;
  bool? deleted;
  ConferenceProperties? conferenceProperties;

  Calendar({
    this.kind,
    this.id,
    this.summary,
    this.description,
    this.location,
    this.timeZone,
    this.summaryOverride,
    this.colorId,
    this.backgroundColor,
    this.foregroundColor,
    this.hidden,
    this.selected,
    this.accessRole,
    this.defaultReminders,
    this.notificationSettings,
    this.primary,
    this.deleted,
    this.conferenceProperties,
  });

  Calendar.fromJson(Map<String, dynamic> json) {
    kind = json['kind'];
    id = json['id'];
    summary = json['summary'];
    description = json['description'];
    location = json['location'];
    timeZone = json['timeZone'];
    summaryOverride = json['summaryOverride'];
    colorId = json['colorId'];
    backgroundColor = json['backgroundColor'];
    foregroundColor = json['foregroundColor'];
    hidden = json['hidden'];
    selected = json['selected'];
    accessRole = json['accessRole'];
    if (json['defaultReminders'] != null) {
      defaultReminders = <DefaultReminders>[];
      json['defaultReminders'].forEach((v) {
        defaultReminders!.add(DefaultReminders.fromJson(v));
      });
    }
    notificationSettings = json['notificationSettings'] != null
        ? NotificationSettings.fromJson(json['notificationSettings'])
        : null;
    primary = json['primary'];
    deleted = json['deleted'];
    conferenceProperties = json['conferenceProperties'] != null
        ? ConferenceProperties.fromJson(json['conferenceProperties'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['kind'] = kind;
    data['id'] = id;
    data['summary'] = summary;
    data['description'] = description;
    data['location'] = location;
    data['timeZone'] = timeZone;
    data['summaryOverride'] = summaryOverride;
    data['colorId'] = colorId;
    data['backgroundColor'] = backgroundColor;
    data['foregroundColor'] = foregroundColor;
    data['hidden'] = hidden;
    data['selected'] = selected;
    data['accessRole'] = accessRole;
    if (defaultReminders != null) {
      data['defaultReminders'] = defaultReminders!.map((v) => v.toJson()).toList();
    }
    if (notificationSettings != null) {
      data['notificationSettings'] = notificationSettings!.toJson();
    }
    data['primary'] = primary;
    data['deleted'] = deleted;
    if (conferenceProperties != null) {
      data['conferenceProperties'] = conferenceProperties!.toJson();
    }
    return data;
  }
}

class CalendarAttendees {
  String? id;
  String? photoUrl;
  String? email;
  String? displayName;
  bool? organizer;
  bool? self;
  bool? resource;
  String? responseStatus;

  CalendarAttendees({
    this.id,
    this.photoUrl,
    this.email,
    this.displayName,
    this.organizer,
    this.self,
    this.resource,
    this.responseStatus,
  });

  CalendarAttendees.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    displayName = json['displayName'];
    photoUrl = json['photoUrl'];
    organizer = json['organizer'];
    self = json['self'];
    resource = json['resource'];
    responseStatus = json['responseStatus'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['email'] = email;
    data['displayName'] = displayName;
    data['photoUrl'] = photoUrl;
    data['organizer'] = organizer;
    data['self'] = self;
    data['resource'] = resource;
    data['responseStatus'] = responseStatus;
    return data;
  }

  // Nuevo método fromGoogleUser
  factory CalendarAttendees.fromGoogleUser(GoogleUser user) {
    return CalendarAttendees(
      id: user.id,
      photoUrl: user.thumbnailPhotoUrl,
      email: user.primaryEmail,
      displayName: user.name?.fullName,
      // Los siguientes campos son específicos del contexto y pueden necesitar ser ajustados
      // Suposición: el GoogleUser no es el organizador por defecto
      organizer: false,
      // Suposición: el GoogleUser no es el mismo que el usuario actual por defecto
      self: false,
      // Suposición: el GoogleUser no es un recurso por defecto
      resource: false,
      // responseStatus se deja sin asignar ya que no hay un campo directamente mapeable en GoogleUser
    );
  }
}

class DefaultReminders {
  String? method;
  int? minutes;

  DefaultReminders({this.method, this.minutes});

  DefaultReminders.fromJson(Map<String, dynamic> json) {
    method = json['method'];
    minutes = json['minutes'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['method'] = method;
    data['minutes'] = minutes;
    return data;
  }
}

class NotificationSettings {
  List<Notifications>? notifications;

  NotificationSettings({this.notifications});

  NotificationSettings.fromJson(Map<String, dynamic> json) {
    if (json['notifications'] != null) {
      notifications = <Notifications>[];
      json['notifications'].forEach((v) {
        notifications!.add(Notifications.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (notifications != null) {
      data['notifications'] = notifications!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Notifications {
  String? type;
  String? method;

  Notifications({this.type, this.method});

  Notifications.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    method = json['method'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['method'] = method;
    return data;
  }
}

class ConferenceProperties {
  List<String>? allowedConferenceSolutionTypes;

  ConferenceProperties({this.allowedConferenceSolutionTypes});

  ConferenceProperties.fromJson(Map<String, dynamic> json) {
    allowedConferenceSolutionTypes = json['allowedConferenceSolutionTypes'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['allowedConferenceSolutionTypes'] = allowedConferenceSolutionTypes;
    return data;
  }
}
