describe('template spec', () => {
  it('passes', () => {
  //Getting response from Visitors Count API website

  cy.request('GET','https://fcyskx0twa.execute-api.us-west-2.amazonaws.com/test/DynamoDBManager').its('body').then((body) =>{
  const visitorsCount = body["body"]["visitorCount"];
  //expect(visitorsCount).to.eq("A1")
  
  cy.request('GET','https://fcyskx0twa.execute-api.us-west-2.amazonaws.com/test/DynamoDBManager').its('body').then((body) =>{
  const visitorsCountNew = body["body"]["visitorCount"];
  expect(visitorsCountNew).to.gt(visitorsCount);
})
  })
  })
})
