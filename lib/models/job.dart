class Job {
  final String id;
  final String title;
  final String status;

  Job({required this.id, required this.title, required this.status});

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      title: json['title'],
      status: json['status'],
    );
  }
}
