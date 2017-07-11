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
	log.debug("---------------------------")
    def issue = issueManager.getIssueObject(documentIssue.id)
    Collection subtasks = issue.getSubTaskObjects();
    log.debug("TASK: ${issue.key} - subtasks: ${subtasks.size()} ( ${issue.originalEstimate})")
    
    long estimateSeconds = 0L
    subtasks.each{subtask->
        log.debug(" - current estimate: ${estimateSeconds} + ${subtask.originalEstimate} ")
        if(subtask.originalEstimate !=  null){
            long subtaskOriginalEstimate = subtask.originalEstimate
        	estimateSeconds += subtaskOriginalEstimate
        }
        log.debug(" - subtask: ${subtask.key} ( ${subtask.originalEstimate} )")
    }
	log.debug("set to: ${estimateSeconds}")
    IssueInputParameters issueInputParameters = issueService.newIssueInputParameters()
	log.debug("${estimateSeconds}s")
    long calc = estimateSeconds/new Long(60)
    issueInputParameters.setOriginalEstimate(calc)
    
    def update = issueService.validateUpdate(user, issue.id, issueInputParameters)
        if (update.isValid()) {
            issueService.update(user, update)
        }
    log.debug("===================")
    log.debug("${issue.key} total_time: ${issue.originalEstimate}")
	log.debug(" ")
}
