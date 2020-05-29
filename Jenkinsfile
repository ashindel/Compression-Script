def sources = [
	Dev: 'its104',
	Test: 'its105',
	Production: 'its106'
]


pipeline
{
	agent any
	environment {
		SRVCREDS = credentials('e1566191-73a8-4042-8ed5-72e0df0a62ee')
		siteLabel = "${params.Site}"
		StageToArchive = "${params.StageToArchive}"
	}
	stages
	{
		stage('Search and Compress')
		{
			steps
			{
				powerScript()
			}
		}
	}
}
void powerScript() {
	powershell script: "./compress.ps1"
}
