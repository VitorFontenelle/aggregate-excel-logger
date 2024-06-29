/**
 * @description Class for bypassing the 2000 record limit for Salesforce Aggregate Queries.
 *              The resulting log will be able to be copied and pasted to a Excel sheet.
 * @class       AggregateExcelLogger
 * @note        This usually gets up to 10-12k aggregate records for execution.
 *              If you need more than that, you can create a Schedulable class with this logic.
 *              Schedule it for a few seconds in the future and you will be able to get your results in a few logs.
 * @author      Vitor Fontenelle
 */
public class AggregateExcelLogger 
{   
	// This defines the maximum number of iterations. 
	// By experience, if your org has a lot of records, 5 is probably the limit you'll be able to 
	// iterate before the timeout limit, but it may be more or less.
	private static final Integer MAX_ITERATIONS = 5;
	
	/**
	 * @description Sample method to log multiple Aggregate Queries in sequence into an Excel exportable format.
	 * @author Vitor Fontenelle
	 * @param startDateTime DateTime to mark the CreatedDate start.
	 */
	public static void logAggregateQuery(DateTime startDateTime) 
	{
		String downloadableList = '';

		List<AggregateResult> accountList = aggregateQuery(startDateTime);
		
		for(AggregateResult acc : accountList)
		{
			downloadableList += acc.get('Quantity') + ',' 
							 + acc.get('Id01') + ',' 
							 + acc.get('Id02') + ',' 
							 + acc.get('MaxDate') + '\n';
		}
		
		// Once you download the log, just copy this debug and paste it in your Excel sheet using "," as separator and you will get your table.
		System.debug(downloadableList);
		System.debug('startDateTime for next iteration: ' + datetime.valueOf(accountList[accountList.size() - 1].get('MaxDate')));
	}
	
	/**
	 * @description This specific query checks for duplicate Accounts with the same Name and different Id's,
	 *              but you can adjust it as per your requirements.
	 * @author Vitor Fontenelle
	 * @param startDateTime DateTime to mark the CreatedDate start.
	 */
	private static List<AggregateResult> aggregateQuery (DateTime startDateTime)
	{
		List<AggregateResult> accountList = new List<AggregateResult>();
		DateTime nextExecutionDateTime;
		
		for(Integer i = 0; i < MAX_ITERATIONS; i++)
		{
			if(nextExecutionDateTime == null || accountList.size() > 1)
			{
				nextExecutionDateTime = (nextExecutionDateTime == null)? (startDateTime) : (datetime.valueOf(accountList[accountList.size() - 1].get('MaxDate')));
				
				List<AggregateResult> accListAux = 
				[
					SELECT Name, COUNT(Id) Quantity, MAX(Id) Id01, MIN(Id) Id02, MAX(CreatedDate) MaxDate
					FROM Account
					GROUP BY Name
					HAVING COUNT(Id) > 1
					AND MAX(CreatedDate) > :nextExecutionDateTime
					ORDER BY MAX(CreatedDate) ASC
					LIMIT 2000
				];
				
				if(accListAux.size() > 0) accountList.addAll(accListAux);
			}
		}
		
		return accountList;
	}
}