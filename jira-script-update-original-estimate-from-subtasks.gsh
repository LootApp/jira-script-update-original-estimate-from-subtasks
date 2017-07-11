import com.atlassian.jira.component.ComponentAccessor
import com.atlassian.jira.issue.search.SearchProvider
import com.atlassian.jira.jql.parser.JqlQueryParser
import com.atlassian.jira.web.bean.PagerFilter
import com.atlassian.jira.bc.issue.IssueService
import com.atlassian.jira.issue.IssueInputParameters

def jqlQueryParser = ComponentAccessor.getComponent(JqlQueryParser)
def searchProvider = ComponentAccessor.getComponent(SearchProvider)
def issueManager = ComponentAccessor.getIssueManager()
def user = ComponentAccessor.getJiraAuthenticationContext().getLoggedInUser()

// edit this query to suit
IssueService issueService = ComponentAccessor.getIssueService();

def query = jqlQueryParser.parseQuery("type = Story AND originalEstimate is EMPTY AND project = TEST")

def results = searchProvider.search(query, user, PagerFilter.getUnlimitedFilter())

log.debug("Total issues for processing: ${results.getTotal()}")

results.getIssues().each {documentIssue ->

    def issue = issueManager.getIssueObject(documentIssue.id)
    
    Collection subtasks = issue.getSubTaskObjects();
    long estimate_seconds = 0
    subtasks.each{subtask->
        estimate_seconds += subtask.originalEstimate
        log.debug("subtask: ${subtask.key} = ${subtask.originalEstimate}")
    }

    IssueInputParameters issueInputParameters = issueService.newIssueInputParameters()
	issueInputParameters.setOriginalEstimate(estimate_seconds)
    
    def update = issueService.validateUpdate(user, issue.id, issueInputParameters)
        if (update.isValid()) {
            issueService.update(user, update)
        }
    
    log.debug("total_time: ${estimate_seconds}")
	log.debug("subtasks: ${subtasks.size()}")
}
