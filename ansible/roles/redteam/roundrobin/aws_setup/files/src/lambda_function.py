import boto3
import os
import time

# Initialize the EC2 client - default eu-west-3
REGION = os.environ.get('EC2_REGION', 'eu-west-3')

ec2 = boto3.client('ec2', region_name=REGION)

# Retrieve instance IDs from environment variables
INSTANCE_ID_1 = os.environ['INSTANCE_ID_1']
INSTANCE_ID_2 = os.environ['INSTANCE_ID_2']

def wait_for_instance_state(instance_id, desired_state, timeout=300, interval=5):
    """
    Wait for an EC2 instance to reach a desired state.
    """
    start_time = time.time()
    
    while time.time() - start_time < timeout:
        response = ec2.describe_instances(InstanceIds=[instance_id])
        state = response['Reservations'][0]['Instances'][0]['State']['Name']
        
        if state == desired_state:
            return True
        time.sleep(interval)
    
    return False

def get_instance_ip(instance_id):
    """
    Retrieve the public IP address of an EC2 instance.
    """
    response = ec2.describe_instances(InstanceIds=[instance_id])
    instances = response['Reservations'][0]['Instances']
    if instances:
        return instances[0].get('PublicIpAddress')
    return None

def lambda_handler(event, context):
    # Describe instances to get their current state
    response = ec2.describe_instances(InstanceIds=[INSTANCE_ID_1, INSTANCE_ID_2])
    instance_status = {instance['InstanceId']: instance['State']['Name'] for reservation in response['Reservations'] for instance in reservation['Instances']}
    
    if instance_status[INSTANCE_ID_1] == 'running':
        # Start INSTANCE_ID_2 and wait for it to be running
        ec2.start_instances(InstanceIds=[INSTANCE_ID_2])
        if wait_for_instance_state(INSTANCE_ID_2, 'running'):
            # Retrieve the IP address of INSTANCE_ID_2
            ip_address = get_instance_ip(INSTANCE_ID_2)
            # Stop INSTANCE_ID_1
            ec2.stop_instances(InstanceIds=[INSTANCE_ID_1])
            return f"Started {INSTANCE_ID_2} (IP: {ip_address}) and stopped {INSTANCE_ID_1}"
        else:
            return f"Failed to start {INSTANCE_ID_2} within the timeout period"
    
    else:
        # Start INSTANCE_ID_1 and wait for it to be running
        ec2.start_instances(InstanceIds=[INSTANCE_ID_1])
        if wait_for_instance_state(INSTANCE_ID_1, 'running'):
            # Retrieve the IP address of INSTANCE_ID_1
            ip_address = get_instance_ip(INSTANCE_ID_1)
            # Stop INSTANCE_ID_2
            ec2.stop_instances(InstanceIds=[INSTANCE_ID_2])
            return f"Started {INSTANCE_ID_1} (IP: {ip_address}) and stopped {INSTANCE_ID_2}"
        else:
            return f"Failed to start {INSTANCE_ID_1} within the timeout period"

