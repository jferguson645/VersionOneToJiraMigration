# VersionOneToJiraMigration

Script to migrate stories from VersionOne to JIRA

Exports VersionOne data to a templated CSV that can then be easily imported into JIRA via their file import tool.

Exports stories and all related tasks and tests.

```bash
Usage: migrate.pl --name <file name> --user <user_name> --url <url_param> --type <type> --cards <number> <number> <number> ...
    --name <file_name>  - added to csv file name for reference (optional)
    --user <user_name>  - Version One username (required)
    --url <url_param>   - Version One Company URL Parameter (required)
    --type <type>       - Story or Defect (required)
    --cards             - space delimited list of cards to export (required)
```

You will be prompted for your Version One password. 
