import json
import logging
from pathlib import Path
from pipeline import RAGPipeline

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class RAGEvaluator:
    def __init__(self, pipeline: RAGPipeline, dataset_path: str = "dataset.json"):
        self.pipeline = pipeline
        self.dataset_path = Path(__file__).parent / dataset_path

    def run_evaluation(self):
        with open(self.dataset_path, "r") as f:
            data = json.load(f)
            
        success_count = 0
        total = len(data["queries"])
        
        for item in data["queries"]:
            query = item["query"]
            expected_grounded = item["expected_grounded"]
            q_type = item["type"]
            
            logger.info(f"\nEvaluating [{q_type}]: {query}")
            try:
                response = self.pipeline.query(query)
                
                # Evaluation heuristics
                is_grounded = response.grounded
                has_citations = len(response.sources) > 0
                
                passed = True
                
                if expected_grounded:
                    if not is_grounded or not has_citations:
                        passed = False
                        logger.error("FAILED: Expected grounded response with citations.")
                else:
                    if is_grounded:
                        passed = False
                        logger.error("FAILED: Expected ungrounded/refusal response.")
                        
                if passed:
                    logger.info("PASSED")
                    success_count += 1
                    
            except Exception as e:
                logger.error(f"Error evaluating query: {e}")
                
        logger.info(f"\nEvaluation Complete: {success_count}/{total} passed.")

if __name__ == "__main__":
    pipeline = RAGPipeline()
    evaluator = RAGEvaluator(pipeline)
    evaluator.run_evaluation()
