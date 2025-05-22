"""
Initial migration: create scan_jobs table
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '0001'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        'scan_jobs',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.String(length=64), nullable=False),
        sa.Column('status', sa.String(length=32), nullable=False),
        sa.Column('baseline_url', sa.String(length=256)),
        sa.Column('plan_url', sa.String(length=256)),
        sa.Column('summary_json', sa.JSON),
        sa.Column('created_at', sa.DateTime, server_default=sa.func.now(), nullable=False),
    )

def downgrade():
    op.drop_table('scan_jobs') 