"""SNS Provider for publishing messages to AWS SNS topics."""

import boto3
from botocore.exceptions import ClientError
from typing import Optional, Dict, Any
import json
import os
import dotenv

env = dotenv.load_dotenv()

class SNSProvider:
    """
    A provider class for interacting with Amazon SNS (Simple Notification Service).
    
    This class provides methods for publishing messages to SNS topics.
    
    Attributes:
        sns_client: The boto3 SNS client instance used for AWS operations
    """
    
    def __init__(self, credentials: Optional[Dict[str, str]] = None):
        """
        Initialize the SNSProvider with a boto3 SNS client.
        
        Args:
            credentials: Optional dictionary with AWS credentials
                - aws_access_key_id: AWS access key
                - aws_secret_access_key: AWS secret key
                - region_name: AWS region name
        """
        if credentials is None:
            credentials = {
                'aws_access_key_id':os.getenv('AWS_ACCESS_KEY_ID'),
                'aws_secret_access_key':os.getenv('AWS_SECRET_ACCESS_KEY'),
                'region_name':os.getenv('AWS_REGION')
            }
        
        aws_access_key_id = credentials.get('aws_access_key_id')
        aws_secret_access_key = credentials.get('aws_secret_access_key')
        region_name = credentials.get('region_name', 'us-east-1')
        
        # Initialize SNS client
        if aws_access_key_id and aws_secret_access_key:
            self.sns_client = boto3.client(
                'sns',
                aws_access_key_id=aws_access_key_id,
                aws_secret_access_key=aws_secret_access_key,
                region_name=region_name
            )
        else:
            # Use default credentials from environment or IAM role
            self.sns_client = boto3.client('sns', region_name=region_name)
    
    def publish_message(
        self,
        topic_arn: str,
        message: Dict[str, Any],
        subject: Optional[str] = None
    ) -> str:
        """
        Publish a message to an SNS topic.
        
        Args:
            topic_arn: The ARN of the SNS topic
            message: Dictionary containing the message data (will be JSON serialized)
            subject: Optional subject for the message
            
        Returns:
            The message ID returned by SNS
            
        Raises:
            ClientError: If the publish operation fails
        """
        try:
            # Convert message dict to JSON string
            message_json = json.dumps(message, ensure_ascii=False, default=str)
            
            # Prepare publish parameters
            publish_params = {
                'TopicArn': topic_arn,
                'Message': message_json,
            }
            
            if subject:
                publish_params['Subject'] = subject
            
            # Publish message
            response = self.sns_client.publish(**publish_params)
            
            message_id = response['MessageId']
            print(f"✓ SNS message published successfully. MessageId: {message_id}")
            
            return message_id
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']
            print(f"❌ Error publishing to SNS: {error_code} - {error_message}")
            raise
        except Exception as e:
            print(f"❌ Unexpected error publishing to SNS: {e}")
            raise
    
    def publish_text_message(
        self,
        topic_arn: str,
        message: str,
        subject: Optional[str] = None
    ) -> str:
        """
        Publish a plain text message to an SNS topic.
        
        Args:
            topic_arn: The ARN of the SNS topic
            message: Plain text message string
            subject: Optional subject for the message
            
        Returns:
            The message ID returned by SNS
            
        Raises:
            ClientError: If the publish operation fails
        """
        try:
            publish_params = {
                'TopicArn': topic_arn,
                'Message': message,
            }
            
            if subject:
                publish_params['Subject'] = subject
            
            response = self.sns_client.publish(**publish_params)
            
            message_id = response['MessageId']
            print(f"✓ SNS text message published successfully. MessageId: {message_id}")
            
            return message_id
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']
            print(f"❌ Error publishing to SNS: {error_code} - {error_message}")
            raise
        except Exception as e:
            print(f"❌ Unexpected error publishing to SNS: {e}")
            raise

